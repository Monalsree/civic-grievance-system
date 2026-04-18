"""
Trend Analysis - Analyze complaint trends over time.
"""

import sqlite3
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))
from config import Config  # type: ignore


def get_db():
    db = sqlite3.connect(Config.DATABASE_PATH)
    db.row_factory = sqlite3.Row
    return db


def complaints_by_category():
    """Get complaint count grouped by category."""
    db = get_db()
    rows = db.execute(
        'SELECT category, COUNT(*) as count FROM complaints GROUP BY category ORDER BY count DESC'
    ).fetchall()
    db.close()
    return [dict(r) for r in rows]


def complaints_by_status():
    """Get complaint count grouped by status."""
    db = get_db()
    rows = db.execute(
        'SELECT status, COUNT(*) as count FROM complaints GROUP BY status'
    ).fetchall()
    db.close()
    return [dict(r) for r in rows]


def complaints_over_time(days=30):
    """Get daily complaint count for the last N days."""
    db = get_db()
    rows = db.execute(
        '''SELECT DATE(created_at) as date, COUNT(*) as count
           FROM complaints
           WHERE created_at >= DATE('now', ?)
           GROUP BY DATE(created_at)
           ORDER BY date''',
        (f'-{days} days',)
    ).fetchall()
    db.close()
    return [dict(r) for r in rows]


def top_departments():
    """Get departments with the most complaints."""
    db = get_db()
    rows = db.execute(
        'SELECT department, COUNT(*) as count FROM complaints GROUP BY department ORDER BY count DESC'
    ).fetchall()
    db.close()
    return [dict(r) for r in rows]


if __name__ == '__main__':
    print("📊 Complaints by Category:", complaints_by_category())
    print("📊 Complaints by Status:", complaints_by_status())
    print("📊 Daily Trend (30 days):", complaints_over_time())
    print("📊 Top Departments:", top_departments())
