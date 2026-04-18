"""
Database Migration: Add upvotes support
Run this script once to add the upvotes column and complaint_upvotes table
to the existing database without losing data.
"""
import sqlite3
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))
from config import Config

def migrate():
    db = sqlite3.connect(Config.DATABASE_PATH)
    cursor = db.cursor()

    # Add upvotes column to complaints if it doesn't exist
    try:
        cursor.execute("ALTER TABLE complaints ADD COLUMN upvotes INTEGER DEFAULT 0")
        print("[SUCCESS] Added 'upvotes' column to complaints table")
    except sqlite3.OperationalError as e:
        if 'duplicate column' in str(e).lower():
            print("[INFO] 'upvotes' column already exists")
        else:
            print(f"[ERROR] Adding upvotes column: {e}")

    # Create complaint_upvotes table
    try:
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS complaint_upvotes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                complaint_id TEXT NOT NULL,
                username TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(complaint_id, username),
                FOREIGN KEY (complaint_id) REFERENCES complaints(id)
            )
        """)
        print("[SUCCESS] Created 'complaint_upvotes' table")
    except Exception as e:
        print(f"[ERROR] Creating table: {e}")

    db.commit()
    db.close()
    print("Migration sequence finished.")

if __name__ == '__main__':
    migrate()
