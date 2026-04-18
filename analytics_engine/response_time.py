"""
Response Time Analysis - Track department response/resolution metrics.
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


def avg_resolution_time():
    """Average resolution time (in hours) for resolved complaints, grouped by department."""
    db = get_db()
    rows = db.execute(
        '''SELECT department,
                  COUNT(*) as resolved_count,
                  AVG((julianday(resolved_at) - julianday(created_at)) * 24) as avg_hours
           FROM complaints
           WHERE status = 'resolved' AND resolved_at IS NOT NULL
           GROUP BY department
           ORDER BY avg_hours'''
    ).fetchall()
    db.close()
    return [dict(r) for r in rows]


def pending_complaints_age():
    """Get pending complaints sorted by age (oldest first)."""
    db = get_db()
    rows = db.execute(
        '''SELECT id, category, department, status, created_at,
                  ROUND((julianday('now') - julianday(created_at)) * 24, 1) as age_hours
           FROM complaints
           WHERE status != 'resolved'
           ORDER BY created_at ASC'''
    ).fetchall()
    db.close()
    return [dict(r) for r in rows]


def department_performance():
    """Get overall department performance metrics."""
    db = get_db()
    rows = db.execute(
        '''SELECT department,
                  COUNT(*) as total,
                  SUM(CASE WHEN status = 'resolved' THEN 1 ELSE 0 END) as resolved,
                  ROUND(SUM(CASE WHEN status = 'resolved' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1) as resolution_rate
           FROM complaints
           GROUP BY department
           ORDER BY resolution_rate DESC'''
    ).fetchall()
    db.close()
    return [dict(r) for r in rows]


if __name__ == '__main__':
    print("⏱️ Average Resolution Time:", avg_resolution_time())
    print("📋 Pending Complaints:", pending_complaints_age())
    print("🏢 Department Performance:", department_performance())
