-- ===================================
-- Civic Grievance System Database Schema
-- ===================================

-- Complaints Table
CREATE TABLE IF NOT EXISTS complaints (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    category TEXT NOT NULL,
    location TEXT NOT NULL,
    description TEXT NOT NULL,
    department TEXT,
    priority TEXT DEFAULT 'medium',
    status TEXT DEFAULT 'submitted',
    sentiment_score REAL DEFAULT 0.0,
    urgency_score REAL DEFAULT 5.0,
    frequency_score REAL DEFAULT 5.0,
    impact_score REAL DEFAULT 5.0,
    fuzzy_priority_score REAL DEFAULT 5.0,
    evidence_path TEXT,
    citizen_username TEXT,
    upvotes INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

-- Status History Table (for timeline tracking)
CREATE TABLE IF NOT EXISTS status_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    complaint_id TEXT NOT NULL,
    status TEXT NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    FOREIGN KEY (complaint_id) REFERENCES complaints(id)
);

-- Community Upvotes Table (prevents double voting)
CREATE TABLE IF NOT EXISTS complaint_upvotes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    complaint_id TEXT NOT NULL,
    username TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(complaint_id, username),
    FOREIGN KEY (complaint_id) REFERENCES complaints(id)
);

-- Analytics Table
CREATE TABLE IF NOT EXISTS analytics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category TEXT NOT NULL,
    department TEXT NOT NULL,
    avg_resolution_hours REAL,
    total_complaints INTEGER DEFAULT 0,
    resolved_complaints INTEGER DEFAULT 0,
    period TEXT,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users / Admin Table
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT DEFAULT 'citizen',
    name TEXT,
    email TEXT,
    phone TEXT,
    department TEXT,
    employee_id TEXT,
    designation TEXT,
    role_level TEXT DEFAULT 'department_admin',
    office_zone TEXT,
    created_by_admin TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default admin
INSERT OR IGNORE INTO users (username, password_hash, role, name, department)
VALUES ('admin', 'admin123', 'admin', 'System Administrator', 'General Administration');

-- Insert default citizen
INSERT OR IGNORE INTO users (username, password_hash, role, name)
VALUES ('user1', 'pass123', 'citizen', 'Demo Citizen');
