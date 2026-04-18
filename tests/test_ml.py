"""Tests for the ML engine and sentiment analysis."""
import sys
import os
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'ml_engine'))

from sentiment_analysis import analyze_sentiment  # type: ignore


class TestSentimentAnalysis(unittest.TestCase):

    def test_high_urgency(self):
        result = analyze_sentiment("Emergency! Gas leak and fire hazard, need immediate help!")
        self.assertEqual(result['priority'], 'high')
        self.assertGreater(result['score'], 0.5)

    def test_medium_urgency(self):
        result = analyze_sentiment("Road is broken and damaged for weeks")
        self.assertEqual(result['priority'], 'medium')

    def test_low_urgency(self):
        result = analyze_sentiment("Suggestion to improve park maintenance")
        self.assertEqual(result['priority'], 'low')

    def test_empty_text(self):
        result = analyze_sentiment("")
        self.assertEqual(result['priority'], 'medium')
        self.assertEqual(result['score'], 0.5)

    def test_none_text(self):
        result = analyze_sentiment(None)
        self.assertEqual(result['priority'], 'medium')

    def test_returns_dict_keys(self):
        result = analyze_sentiment("Some complaint text")
        self.assertIn('priority', result)
        self.assertIn('score', result)
        self.assertIn('urgency_level', result)


class TestFuzzyPriority(unittest.TestCase):

    def setUp(self):
        sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'soft_computing'))
        from fuzzy_priority_engine import compute_priority  # type: ignore
        self.compute_priority = compute_priority

    def test_high_priority(self):
        result = self.compute_priority(9, 8, 9)
        self.assertEqual(result['priority'], 'high')

    def test_low_priority(self):
        result = self.compute_priority(1, 1, 1)
        self.assertEqual(result['priority'], 'low')

    def test_medium_priority(self):
        result = self.compute_priority(5, 5, 5)
        self.assertEqual(result['priority'], 'medium')

    def test_returns_dict_keys(self):
        result = self.compute_priority(5, 5, 5)
        self.assertIn('priority', result)
        self.assertIn('score', result)
        self.assertIn('label', result)


if __name__ == '__main__':
    unittest.main()
