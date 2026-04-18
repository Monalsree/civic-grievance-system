"""
API Routes - REST API endpoints for the Civic Grievance System.
Includes: Auth, CRUD, Fuzzy Priority, Analytics.
"""

import sqlite3
import os
import sys
import uuid
import hashlib
import datetime
from flask import Blueprint, request, jsonify  # type: ignore
from routing_engine import route_complaint  # type: ignore
from notification_service import notify_status_change, get_notifications, create_notification  # type: ignore
from config import Config  # type: ignore

# Add paths for ML and soft computing
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'ml_engine'))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'soft_computing'))

try:
    from gemini_service import classify_complaint as gemini_classify  # type: ignore
    GEMINI_ENABLED = True
except ImportError:
    GEMINI_ENABLED = False

try:
    from fuzzy_priority_engine import compute_priority  # type: ignore
    FUZZY_ENABLED = True
except ImportError:
    FUZZY_ENABLED = False

try:
    from sentiment_analysis import analyze_sentiment  # type: ignore
    SENTIMENT_ENABLED = True
except ImportError:
    SENTIMENT_ENABLED = False

api = Blueprint('api', __name__)


def get_db():
    """Get a database connection."""
    db = sqlite3.connect(Config.DATABASE_PATH)
    db.row_factory = sqlite3.Row
    return db


def init_db():
    """Initialize the database from schema.sql."""
    db = get_db()
    with open(Config.SCHEMA_PATH, 'r') as f:
        db.executescript(f.read())
    db.close()


def hash_password(password):
    """Simple hash for passwords."""
    return hashlib.sha256(password.encode()).hexdigest()


def _ensure_users_professional_columns(db):
    """Ensure users table has columns needed for admin professional onboarding."""
    existing = {
        row['name']
        for row in db.execute("PRAGMA table_info(users)").fetchall()
    }

    if 'employee_id' not in existing:
        db.execute('ALTER TABLE users ADD COLUMN employee_id TEXT')
    if 'designation' not in existing:
        db.execute('ALTER TABLE users ADD COLUMN designation TEXT')
    if 'role_level' not in existing:
        db.execute("ALTER TABLE users ADD COLUMN role_level TEXT DEFAULT 'department_admin'")
    if 'office_zone' not in existing:
        db.execute('ALTER TABLE users ADD COLUMN office_zone TEXT')
    if 'created_by_admin' not in existing:
        db.execute('ALTER TABLE users ADD COLUMN created_by_admin TEXT')
    if 'is_active' not in existing:
        db.execute('ALTER TABLE users ADD COLUMN is_active INTEGER DEFAULT 1')


def _is_professional_email(email):
    """Reject common personal domains for admin onboarding."""
    if '@' not in email:
        return False
    domain = email.split('@')[-1].lower().strip()
    blocked = {'gmail.com', 'yahoo.com', 'outlook.com', 'hotmail.com'}
    return domain not in blocked


# ===================================
# AUTH ENDPOINTS
# ===================================

@api.route('/auth/register', methods=['POST'])
def register():
    """Register a new citizen account."""
    data = request.get_json(silent=True) or {}
    username = (data.get('username') or '').strip()
    email = (data.get('email') or '').strip()
    password = (data.get('password') or '').strip()
    name = (data.get('name') or '').strip()
    phone = (data.get('phone') or '').strip()
    role = (data.get('role') or 'citizen').strip()

    # Use email as username if username not provided
    if not username and email:
        username = email
    
    if not username or not password or not email:
        return jsonify({'error': 'Email, username, and password are required'}), 400
    if len(password) < 4:
        return jsonify({'error': 'Password must be at least 4 characters'}), 400
    
    # Only citizens can self-register. Admin accounts must be created manually.
    if role != 'citizen':
        return jsonify({
            'error': 'Admin accounts are created by the system owner and cannot be self-registered.'
        }), 403

    db = get_db()
    _ensure_users_professional_columns(db)

    existing = db.execute('SELECT id FROM users WHERE username = ? OR email = ?', (username, email)).fetchone()
    if existing:
        db.close()
        return jsonify({'error': 'Username or email already exists'}), 409

    try:
        db.execute(
            'INSERT INTO users (username, password_hash, role, name, email, phone, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
            (username, hash_password(password), role, name, email, phone, datetime.datetime.now().isoformat())
        )
        db.commit()
        user = db.execute('SELECT * FROM users WHERE username = ?', (username,)).fetchone()
        db.close()
        return jsonify({
            'success': True, 
            'message': 'Registration successful', 
            'user': {
                'id': str(user['id']),
                'username': user['username'],
                'email': user['email'],
                'name': user['name'],
                'phone': user['phone'],
                'role': user['role']
            },
            'role': user['role']
        }), 201
    except Exception as e:
        db.close()
        return jsonify({'error': f'Registration failed: {str(e)}'}), 500


@api.route('/auth/admin/create', methods=['POST'])
def create_admin_account():
    """Create a new admin account using setup key and professional identity details."""
    data = request.get_json(silent=True) or {}

    setup_key = (data.get('setup_key') or '').strip()
    username = (data.get('username') or '').strip()
    email = (data.get('email') or '').strip().lower()
    password = (data.get('password') or '').strip()
    name = (data.get('name') or '').strip()
    phone = (data.get('phone') or '').strip()
    employee_id = (data.get('employee_id') or '').strip()
    department = (data.get('department') or '').strip()
    designation = (data.get('designation') or '').strip()
    role_level = (data.get('role_level') or 'department_admin').strip()
    office_zone = (data.get('office_zone') or '').strip()
    created_by = (data.get('created_by_admin') or '').strip()

    if setup_key != Config.ADMIN_SETUP_KEY:
        return jsonify({'error': 'Invalid admin setup key'}), 403

    required = [username, email, password, name, phone, employee_id, department, designation]
    if any(not field for field in required):
        return jsonify({'error': 'Missing required professional admin fields'}), 400

    if len(password) < 6:
        return jsonify({'error': 'Password must be at least 6 characters'}), 400

    if not _is_professional_email(email):
        return jsonify({'error': 'Use an official organization email for admin accounts'}), 400

    allowed_levels = {'super_admin', 'department_admin', 'staff_officer'}
    if role_level not in allowed_levels:
        return jsonify({'error': 'Invalid role level'}), 400

    db = get_db()
    _ensure_users_professional_columns(db)

    existing = db.execute(
        'SELECT id FROM users WHERE username = ? OR email = ? OR employee_id = ?',
        (username, email, employee_id)
    ).fetchone()
    if existing:
        db.close()
        return jsonify({'error': 'Username, email, or employee ID already exists'}), 409

    try:
        db.execute(
            '''INSERT INTO users
               (username, password_hash, role, name, email, phone, department,
                employee_id, designation, role_level, office_zone, created_by_admin, is_active, created_at)
               VALUES (?, ?, 'admin', ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)''',
            (
                username,
                hash_password(password),
                name,
                email,
                phone,
                department,
                employee_id,
                designation,
                role_level,
                office_zone,
                created_by,
                datetime.datetime.now().isoformat(),
            )
        )
        db.commit()
        user = db.execute('SELECT * FROM users WHERE username = ?', (username,)).fetchone()
        db.close()

        return jsonify({
            'success': True,
            'message': 'Admin account created successfully',
            'user': {
                'id': str(user['id']),
                'username': user['username'],
                'role': user['role'],
                'name': user['name'] or '',
                'email': user['email'] or '',
                'phone': user['phone'] or '',
                'department': user['department'] or '',
                'employee_id': user['employee_id'] or '',
                'designation': user['designation'] or '',
                'role_level': user['role_level'] or 'department_admin',
                'office_zone': user['office_zone'] or '',
                'created_by_admin': user['created_by_admin'] or '',
                'is_active': bool(user['is_active']),
            },
        }), 201
    except Exception as e:
        db.close()
        return jsonify({'error': f'Admin account creation failed: {str(e)}'}), 500


@api.route('/auth/login', methods=['POST'])
def login():
    """Login with email/username and password."""
    data = request.get_json(silent=True) or {}
    username_or_email = (data.get('username') or data.get('email') or '').strip()
    password = (data.get('password') or '').strip()

    if not username_or_email or not password:
        return jsonify({'error': 'Email/username and password are required'}), 400

    db = get_db()
    user = db.execute('SELECT * FROM users WHERE username = ? OR email = ?', (username_or_email, username_or_email)).fetchone()
    db.close()

    if not user:
        return jsonify({'error': 'Invalid username or password'}), 401

    # Check password (support both hashed and plain for default admin)
    stored_hash = user['password_hash']
    if stored_hash == password or stored_hash == hash_password(password):
        # Generate a simple token (in production, use JWT)
        token = hashlib.sha256(f"{user['username']}{datetime.datetime.now().isoformat()}".encode()).hexdigest()
        return jsonify({
            'status': 'success',
            'message': 'Login successful',
            'success': True,
            'token': token,
            'access_token': token,
            'user': {
                'id': str(user['id']),
                'username': user['username'],
                'role': user['role'],
                'name': user['name'] or user['username'],
                'email': user['email'] or '',
                'phone': user['phone'] or '',
                'department': user['department'] or '',
            }
        }), 200
    else:
        return jsonify({'error': 'Invalid username or password'}), 401


# ===================================
# COMPLAINT ENDPOINTS
# ===================================

@api.route('/complaints', methods=['POST'])
def create_complaint():
    """Submit a new complaint with fuzzy priority calculation."""
    raw_data = request.form.to_dict() if request.form else (request.get_json(silent=True) or {})
    data = dict(raw_data)
    required_fields = ['name', 'phone', 'category', 'location', 'description']
    for field in required_fields:
        if not data.get(field):
            return jsonify({'error': f'Missing required field: {field}'}), 400

    hex_str = uuid.uuid4().hex
    complaint_id = 'CG' + datetime.datetime.now().strftime('%Y%m%d%H%M%S') + hex_str[:4].upper()
    department = route_complaint(data['category'], data['description'])

    # --- Fuzzy Priority Calculation ---
    urgency_score = 5.0
    frequency_score = 5.0
    impact_score = 5.0
    priority = 'medium'
    fuzzy_priority_score = 5.0

    # Step 1: Sentiment analysis for urgency
    if SENTIMENT_ENABLED:
        try:
            sentiment = analyze_sentiment(data['description'])
            urgency_map = {'Low': 3.0, 'Medium': 5.0, 'High': 8.0}
            urgency_score = urgency_map.get(sentiment.get('priority', 'Medium'), 5.0)
        except Exception:
            pass

    # Step 2: AI provider (GLM/Gemini) for better classification
    if GEMINI_ENABLED:
        try:
            ai_result = gemini_classify(data['description'])
            if ai_result and ai_result.get('source') in ('gemini-ai', 'glm-ai'):
                department = ai_result.get('department', department)
                ai_urgency = ai_result.get('urgency_score')
                if ai_urgency and isinstance(ai_urgency, (int, float)):
                    urgency_score = float(ai_urgency)
        except Exception:
            pass

    # Step 3: Frequency — count similar complaints in last 30 days
    db = get_db()
    try:
        freq_count = db.execute(
            "SELECT COUNT(*) as c FROM complaints WHERE category = ? AND created_at >= datetime('now', '-30 days')",
            (data['category'],)
        ).fetchone()['c']
        frequency_score = min(10.0, max(1.0, freq_count / 3.0))
    except Exception:
        frequency_score = 5.0

    # Step 4: Impact based on category
    high_impact_cats = ['electricity', 'water', 'sanitation']
    medium_impact_cats = ['roads', 'garbage', 'drainage']
    cat_lower = data['category'].lower().strip()
    if cat_lower in high_impact_cats:
        impact_score = 7.5
    elif cat_lower in medium_impact_cats:
        impact_score = 5.5
    else:
        impact_score = 4.0

    # Step 5: Compute fuzzy priority
    if FUZZY_ENABLED:
        try:
            fuzzy_result = compute_priority(urgency_score, frequency_score, impact_score)
            priority = fuzzy_result['priority']
            fuzzy_priority_score = fuzzy_result['score']
        except Exception:
            pass

    # Insert complaint
    db.execute(
        '''INSERT INTO complaints 
           (id, name, email, phone, category, location, description, department, 
            priority, status, urgency_score, frequency_score, impact_score, 
            fuzzy_priority_score, citizen_username, latitude, longitude)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        (complaint_id, data['name'], data['email'], data['phone'],
         data['category'], data['location'], data['description'],
         department, priority, 'submitted',
         urgency_score, frequency_score, impact_score, fuzzy_priority_score,
         data.get('username', ''), data.get('latitude'), data.get('longitude'))
    )
    db.execute(
        'INSERT INTO status_history (complaint_id, status) VALUES (?, ?)',
        (complaint_id, 'submitted')
    )
    db.commit()
    db.close()

    # Create notification for the user
    short_desc = data['description'] if len(data['description']) <= 50 else data['description'][:47] + '...'
    create_notification(complaint_id, f"Complaint registered: {short_desc}", notif_type='info')

    return jsonify({
        'success': True,
        'complaint_id': complaint_id,
        'department': department,
        'priority': priority,
        'fuzzy_score': fuzzy_priority_score,
        'status': 'submitted',
        'message': 'Complaint submitted successfully'
    }), 201


@api.route('/complaints', methods=['GET'])
def list_complaints():
    """List all complaints, sorted by priority score (high first)."""
    db = get_db()
    rows = db.execute(
        'SELECT * FROM complaints ORDER BY fuzzy_priority_score DESC, created_at DESC'
    ).fetchall()
    db.close()
    return jsonify([dict(r) for r in rows]), 200


@api.route('/complaints/mine', methods=['GET'])
def my_complaints():
    """Get complaints for a specific citizen by phone or username."""
    phone = request.args.get('phone', '').strip()
    username = request.args.get('username', '').strip()

    if not phone and not username:
        return jsonify({'error': 'Phone or username required'}), 400

    db = get_db()
    if phone:
        rows = db.execute(
            'SELECT * FROM complaints WHERE phone = ? ORDER BY created_at DESC', (phone,)
        ).fetchall()
    else:
        rows = db.execute(
            'SELECT * FROM complaints WHERE citizen_username = ? ORDER BY created_at DESC', (username,)
        ).fetchall()
    db.close()
    return jsonify([dict(r) for r in rows]), 200


@api.route('/complaints/<complaint_id>', methods=['GET'])
def get_complaint(complaint_id):
    """Get a single complaint by ID."""
    db = get_db()
    row = db.execute('SELECT * FROM complaints WHERE id = ?', (complaint_id,)).fetchone()
    if not row:
        db.close()
        return jsonify({'error': 'Complaint not found'}), 404
    history = db.execute(
        'SELECT * FROM status_history WHERE complaint_id = ? ORDER BY changed_at', (complaint_id,)
    ).fetchall()
    db.close()
    result = dict(row)
    result['history'] = [dict(h) for h in history]
    return jsonify(result), 200


@api.route('/complaints/search', methods=['GET'])
def search_complaints():
    """Search complaints by ID or phone number."""
    query = request.args.get('q', '').strip()
    if not query:
        return jsonify({'error': 'Search query is required'}), 400

    db = get_db()
    rows = db.execute(
        'SELECT * FROM complaints WHERE id = ? OR phone = ? ORDER BY created_at DESC',
        (query, query)
    ).fetchall()
    db.close()

    if not rows:
        return jsonify({'error': 'No complaints found', 'results': []}), 404

    return jsonify({'results': [dict(r) for r in rows]}), 200


@api.route('/complaints/<complaint_id>/status', methods=['PUT'])
def update_status(complaint_id):
    """Update the status of a complaint (admin)."""
    data = request.get_json(silent=True) or {}
    new_status = data.get('status')
    valid_statuses = ['submitted', 'assigned', 'in-progress', 'resolved']
    if new_status not in valid_statuses:
        return jsonify({'error': f'Invalid status. Must be one of: {valid_statuses}'}), 400

    db = get_db()
    row = db.execute('SELECT status FROM complaints WHERE id = ?', (complaint_id,)).fetchone()
    if not row:
        db.close()
        return jsonify({'error': 'Complaint not found'}), 404

    old_status = row['status']
    now = datetime.datetime.now().isoformat()
    resolved_at = now if new_status == 'resolved' else None

    db.execute(
        'UPDATE complaints SET status = ?, updated_at = ?, resolved_at = ? WHERE id = ?',
        (new_status, now, resolved_at, complaint_id)
    )
    db.execute(
        'INSERT INTO status_history (complaint_id, status, notes) VALUES (?, ?, ?)',
        (complaint_id, new_status, data.get('notes', ''))
    )
    db.commit()
    db.close()

    # notify_status_change(complaint_id, old_status, new_status)
    if new_status == 'in-progress':
        status_text = 'In Progress'
    elif new_status == 'resolved':
        status_text = 'Resolved'
    else:
        status_text = new_status.title()
        
    create_notification(complaint_id, f"Your complaint status changed to {status_text}", notif_type='status_change')
    
    return jsonify({'success': True, 'old_status': old_status, 'new_status': new_status}), 200


# ===================================
# NOTIFICATION ENDPOINTS
# ===================================

@api.route('/notifications', methods=['GET'])
def list_notifications():
    """Get notifications, optionally filtered by complaint_id."""
    complaint_id = request.args.get('complaint_id')
    return jsonify(get_notifications(complaint_id)), 200


# ===================================
# ANALYTICS ENDPOINTS
# ===================================

@api.route('/analytics/summary', methods=['GET'])
def analytics_summary():
    """Get comprehensive analytics summary."""
    db = get_db()
    total = db.execute('SELECT COUNT(*) as c FROM complaints').fetchone()['c']
    resolved = db.execute("SELECT COUNT(*) as c FROM complaints WHERE status = 'resolved'").fetchone()['c']
    pending = db.execute("SELECT COUNT(*) as c FROM complaints WHERE status != 'resolved'").fetchone()['c']
    high_priority = db.execute("SELECT COUNT(*) as c FROM complaints WHERE priority = 'high'").fetchone()['c']

    by_category = db.execute(
        'SELECT category, COUNT(*) as count FROM complaints GROUP BY category'
    ).fetchall()
    by_status = db.execute(
        'SELECT status, COUNT(*) as count FROM complaints GROUP BY status'
    ).fetchall()
    by_priority = db.execute(
        'SELECT priority, COUNT(*) as count FROM complaints GROUP BY priority'
    ).fetchall()
    by_department = db.execute(
        'SELECT department, COUNT(*) as count FROM complaints GROUP BY department ORDER BY count DESC'
    ).fetchall()

    # Recent complaints
    recent = db.execute(
        'SELECT id, category, priority, status, created_at FROM complaints ORDER BY created_at DESC LIMIT 10'
    ).fetchall()

    db.close()

    return jsonify({
        'total': total,
        'resolved': resolved,
        'pending': pending,
        'high_priority': high_priority,
        'resolution_rate': round(float(resolved) / float(total) * 100, 1) if total > 0 else 0.0,
        'by_category': [dict(r) for r in by_category],
        'by_status': [dict(r) for r in by_status],
        'by_priority': [dict(r) for r in by_priority],
        'by_department': [dict(r) for r in by_department],
        'recent': [dict(r) for r in recent],
    }), 200


# ===================================
# COMMUNITY UPVOTE ENDPOINTS
# ===================================

@api.route('/complaints/<complaint_id>/upvote', methods=['POST'])
def upvote_complaint(complaint_id):
    """Upvote a complaint. Each user can only vote once per complaint."""
    data = request.get_json(silent=True) or {}
    username = (data.get('username') or '').strip()
    if not username:
        return jsonify({'error': 'Username is required'}), 400

    db = get_db()
    row = db.execute('SELECT id, upvotes FROM complaints WHERE id = ?', (complaint_id,)).fetchone()
    if not row:
        db.close()
        return jsonify({'error': 'Complaint not found'}), 404

    # Check if already voted
    existing = db.execute(
        'SELECT id FROM complaint_upvotes WHERE complaint_id = ? AND username = ?',
        (complaint_id, username)
    ).fetchone()
    if existing:
        db.close()
        return jsonify({'error': 'You have already upvoted this complaint', 'upvotes': row['upvotes']}), 409

    # Insert vote
    db.execute(
        'INSERT INTO complaint_upvotes (complaint_id, username) VALUES (?, ?)',
        (complaint_id, username)
    )
    new_count = row['upvotes'] + 1
    db.execute(
        'UPDATE complaints SET upvotes = ? WHERE id = ?',
        (new_count, complaint_id)
    )

    # Dynamic priority bump: if upvotes exceed 5, bump priority
    if new_count >= 10:
        db.execute("UPDATE complaints SET priority = 'high' WHERE id = ? AND priority != 'high'", (complaint_id,))
    elif new_count >= 5:
        db.execute("UPDATE complaints SET priority = 'medium' WHERE id = ? AND priority = 'low'", (complaint_id,))

    db.commit()
    db.close()

    return jsonify({'success': True, 'upvotes': new_count, 'message': 'Upvote recorded'}), 200


# ===================================
# PATTERN DETECTION & INSIGHTS
# ===================================

@api.route('/analytics/insights', methods=['GET'])
def analytics_insights():
    """Detect complaint patterns and trends automatically.
    Compares this week vs last week per category to find spikes."""
    db = get_db()

    # This week's complaints by category
    this_week = db.execute(
        """SELECT category, COUNT(*) as count FROM complaints
           WHERE created_at >= date('now', '-7 days')
           GROUP BY category"""
    ).fetchall()

    # Last week's complaints by category
    last_week = db.execute(
        """SELECT category, COUNT(*) as count FROM complaints
           WHERE created_at >= date('now', '-14 days') AND created_at < date('now', '-7 days')
           GROUP BY category"""
    ).fetchall()

    # Top areas (locations) with most complaints
    hotspots = db.execute(
        """SELECT location, COUNT(*) as count FROM complaints
           WHERE created_at >= date('now', '-30 days')
           GROUP BY location ORDER BY count DESC LIMIT 5"""
    ).fetchall()

    # Most upvoted complaints
    trending = db.execute(
        """SELECT id, category, description, upvotes, location FROM complaints
           WHERE upvotes > 0 ORDER BY upvotes DESC LIMIT 5"""
    ).fetchall()

    db.close()

    # Build insights
    this_week_map = {r['category']: r['count'] for r in this_week}
    last_week_map = {r['category']: r['count'] for r in last_week}
    all_cats = set(list(this_week_map.keys()) + list(last_week_map.keys()))

    insights = []
    for cat in all_cats:
        curr = this_week_map.get(cat, 0)
        prev = last_week_map.get(cat, 0)
        if prev > 0 and curr > prev:
            pct = round((curr - prev) / prev * 100)
            insights.append({
                'type': 'spike',
                'category': cat,
                'message': f'{cat.title()} complaints increased {pct}% this week ({prev} → {curr})',
                'severity': 'high' if pct > 100 else 'medium',
                'current': curr,
                'previous': prev,
                'change_pct': pct,
            })
        elif prev > 0 and curr < prev:
            pct = round((prev - curr) / prev * 100)
            insights.append({
                'type': 'decline',
                'category': cat,
                'message': f'{cat.title()} complaints decreased {pct}% this week ({prev} → {curr})',
                'severity': 'low',
                'current': curr,
                'previous': prev,
                'change_pct': -pct,
            })
        elif prev == 0 and curr > 2:
            insights.append({
                'type': 'new_trend',
                'category': cat,
                'message': f'New surge: {curr} {cat.title()} complaints appeared this week',
                'severity': 'medium',
                'current': curr,
                'previous': 0,
                'change_pct': 100,
            })

    return jsonify({
        'insights': sorted(insights, key=lambda x: abs(x.get('change_pct', 0)), reverse=True),
        'hotspots': [dict(r) for r in hotspots],
        'trending': [dict(r) for r in trending],
    }), 200


# ===================================
# FUTURE ISSUE PREDICTION
# ===================================

@api.route('/analytics/predictions', methods=['GET'])
def analytics_predictions():
    """Predict upcoming issues based on historical frequency patterns.
    Uses a simple moving-average approach over 4-week rolling windows."""
    db = get_db()

    # Get weekly complaint counts per category for the last 8 weeks
    weekly = db.execute(
        """SELECT category,
                  strftime('%W', created_at) as week_num,
                  COUNT(*) as count
           FROM complaints
           WHERE created_at >= date('now', '-56 days')
           GROUP BY category, week_num
           ORDER BY category, week_num"""
    ).fetchall()

    # Get seasonal patterns (same month last year as hint)
    seasonal = db.execute(
        """SELECT category, COUNT(*) as count FROM complaints
           WHERE strftime('%m', created_at) = strftime('%m', 'now')
           GROUP BY category ORDER BY count DESC"""
    ).fetchall()

    db.close()

    # Build rolling average per category
    cat_weeks = {}
    for row in weekly:
        cat = row['category']
        if cat not in cat_weeks:
            cat_weeks[cat] = []
        cat_weeks[cat].append(row['count'])

    predictions = []
    for cat, counts in cat_weeks.items():
        if len(counts) < 2:
            continue
        avg = sum(counts) / len(counts)
        recent = counts[-1] if counts else 0
        trend = 'stable'
        if len(counts) >= 3:
            recent_avg = sum(counts[-3:]) / 3
            older_avg = sum(counts[:-3]) / max(1, len(counts) - 3) if len(counts) > 3 else avg
            if recent_avg > older_avg * 1.3:
                trend = 'increasing'
            elif recent_avg < older_avg * 0.7:
                trend = 'decreasing'

        # Generate prediction
        if trend == 'increasing':
            predicted = round(avg * 1.4, 1)
            predictions.append({
                'category': cat,
                'trend': trend,
                'avg_weekly': round(avg, 1),
                'predicted_next_week': predicted,
                'confidence': 'high' if len(counts) >= 4 else 'medium',
                'message': f'{cat.title()} issues are trending up. Predicted ~{predicted:.0f} complaints next week.',
                'risk_level': 'high',
            })
        elif trend == 'stable' and avg > 3:
            predictions.append({
                'category': cat,
                'trend': trend,
                'avg_weekly': round(avg, 1),
                'predicted_next_week': round(avg, 1),
                'confidence': 'medium',
                'message': f'{cat.title()} complaints remain steady at ~{avg:.0f}/week.',
                'risk_level': 'medium',
            })
        elif trend == 'decreasing' and avg > 2:
            predicted = round(avg * 0.7, 1)
            predictions.append({
                'category': cat,
                'trend': trend,
                'avg_weekly': round(avg, 1),
                'predicted_next_week': predicted,
                'confidence': 'medium',
                'message': f'{cat.title()} complaints are declining. Expected ~{predicted:.0f} next week.',
                'risk_level': 'low',
            })

    # Add seasonal warnings
    seasonal_alerts = []
    for row in seasonal:
        if row['count'] > 5:
            seasonal_alerts.append({
                'category': row['category'],
                'message': f'Historically, {row["category"].title()} complaints are high this month ({row["count"]} last year).',
                'risk_level': 'medium',
            })

    return jsonify({
        'predictions': sorted(predictions, key=lambda x: {'high': 0, 'medium': 1, 'low': 2}.get(x['risk_level'], 3)),
        'seasonal_alerts': seasonal_alerts[:5],
    }), 200

