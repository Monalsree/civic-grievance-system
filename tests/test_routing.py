"""Tests for the routing engine."""
import sys
import os
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))

from routing_engine import route_complaint  # type: ignore


class TestRouting(unittest.TestCase):

    def test_known_categories(self):
        self.assertEqual(route_complaint('roads'), 'Public Works Department')
        self.assertEqual(route_complaint('water'), 'Water Supply Department')
        self.assertEqual(route_complaint('electricity'), 'Electricity Board')
        self.assertEqual(route_complaint('sanitation'), 'Sanitation Department')
        self.assertEqual(route_complaint('drainage'), 'Drainage & Sewage Department')
        self.assertEqual(route_complaint('streetlights'), 'Municipal Corporation')
        self.assertEqual(route_complaint('parks'), 'Parks & Recreation Department')
        self.assertEqual(route_complaint('noise'), 'Environmental Department')
        self.assertEqual(route_complaint('other'), 'General Administration')

    def test_case_insensitive(self):
        self.assertEqual(route_complaint('ROADS'), 'Public Works Department')
        self.assertEqual(route_complaint('Water'), 'Water Supply Department')

    def test_unknown_category(self):
        self.assertEqual(route_complaint('unknown'), 'General Administration')
        self.assertEqual(route_complaint(''), 'General Administration')

    def test_none_category(self):
        self.assertEqual(route_complaint(None), 'General Administration')


if __name__ == '__main__':
    unittest.main()
