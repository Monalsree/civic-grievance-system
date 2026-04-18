"""
Sentiment Analysis - Urgency detection for complaints using keyword scoring.
Uses a keyword-based approach (no heavy ML dependency needed).
"""


# Urgency keywords with weights
URGENCY_KEYWORDS = {
    'high': [
        'emergency', 'urgent', 'danger', 'dangerous', 'life-threatening',
        'accident', 'fire', 'flood', 'collapse', 'electric shock',
        'death', 'dying', 'injured', 'critical', 'hazard', 'toxic',
        'immediately', 'asap', 'right now', 'severe', 'fatal',
    ],
    'medium': [
        'broken', 'damaged', 'leaking', 'blocked', 'overflow',
        'not working', 'complaint', 'problem', 'issue', 'days',
        'week', 'delay', 'pending', 'waiting', 'unresolved',
        'bad condition', 'poor', 'dirty', 'unhygienic',
    ],
    'low': [
        'suggestion', 'request', 'improve', 'maintenance', 'minor',
        'small', 'cosmetic', 'painting', 'beautification', 'feedback',
        'regular', 'routine', 'general', 'inquiry',
    ],
}


def analyze_sentiment(text):
    """
    Analyze text sentiment/urgency and return a priority level.
    Returns: dict with 'priority', 'score', and 'urgency_level'
    """
    if not text:
        return {'priority': 'medium', 'score': 0.5, 'urgency_level': 'Medium'}

    text_lower = text.lower()
    scores = {'high': 0, 'medium': 0, 'low': 0}

    for level, keywords in URGENCY_KEYWORDS.items():
        for keyword in keywords:
            if keyword in text_lower:
                scores[level] += 1

    # Determine priority based on highest score
    total = sum(scores.values())
    if total == 0:
        priority = 'medium'
        score = 0.5
    elif scores['high'] > 0:
        priority = 'high'
        score = min(1.0, 0.7 + (scores['high'] * 0.1))
    elif scores['medium'] >= scores['low']:
        priority = 'medium'
        score = 0.4 + (scores['medium'] * 0.05)
    else:
        priority = 'low'
        score = 0.1 + (scores['low'] * 0.05)

    urgency_map = {'high': 'High', 'medium': 'Medium', 'low': 'Low'}

    return {
        'priority': priority,
        'score': round(min(score, 1.0), 4),
        'urgency_level': urgency_map[priority],
    }


if __name__ == '__main__':
    test_texts = [
        "There is a gas leak and fire hazard, need immediate help!",
        "Road has potholes and is damaged since two weeks",
        "Please paint the park bench, it looks old",
        "Water pipe is leaking near the school area",
    ]
    for text in test_texts:
        result = analyze_sentiment(text)
        print(f"Text: {text}")
        print(f"  → Priority: {result['priority']} | Score: {result['score']} | Urgency: {result['urgency_level']}\n")
