"""Tests for the Flask API endpoints."""
import sys
import os
import json
import unittest

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))

from app import app  # type: ignore
from api_routes import init_db  # type: ignore


class TestAPI(unittest.TestCase):
    _complaint_id = None  # class-level declaration

    @classmethod
    def setUpClass(cls):
        app.config['TESTING'] = True
        # Use an in-memory test database
        test_db = os.path.join(os.path.dirname(__file__), 'test_grievances.db')
        from config import Config  # type: ignore
        Config.DATABASE_PATH = test_db
        with app.app_context():
            init_db()

    def setUp(self):
        self.client = app.test_client()

    @classmethod
    def tearDownClass(cls):
        test_db = os.path.join(os.path.dirname(__file__), 'test_grievances.db')
        if os.path.exists(test_db):
            os.remove(test_db)

    def test_health_check(self):
        response = self.client.get('/health')
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data['status'], 'healthy')

    def test_home(self):
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data['status'], 'online')

    def test_create_complaint(self):
        response = self.client.post('/api/complaints', json={
            'name': 'Test User',
            'email': 'test@example.com',
            'phone': '9876543210',
            'category': 'roads',
            'location': 'Test Location',
            'description': 'Pothole on main road'
        })
        self.assertEqual(response.status_code, 201)
        data = response.get_json()
        self.assertTrue(data['success'])
        self.assertIn('complaint_id', data)
        self.__class__._complaint_id = data['complaint_id']

    def test_create_complaint_missing_fields(self):
        response = self.client.post('/api/complaints', json={
            'name': 'Test User',
        })
        self.assertEqual(response.status_code, 400)

    def test_list_complaints(self):
        response = self.client.get('/api/complaints')
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertIsInstance(data, list)

    def test_search_complaints(self):
        response = self.client.get('/api/complaints/search?q=9876543210')
        self.assertEqual(response.status_code, 200)

    def test_analytics_summary(self):
        response = self.client.get('/api/analytics/summary')
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertIn('total', data)


if __name__ == '__main__':
    unittest.main()
