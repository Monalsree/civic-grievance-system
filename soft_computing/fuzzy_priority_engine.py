"""
Fuzzy Priority Engine - Uses fuzzy logic to determine complaint priority.
Inputs: urgency_score (0-10), frequency (0-10), impact_score (0-10)
Output: Priority level (Low / Medium / High)
"""


def triangular_mf(x, a, b, c):
    """Triangular membership function."""
    if x <= a or x >= c:
        return 0.0
    elif a < x <= b:
        return (x - a) / (b - a) if b != a else 1.0
    else:
        return (c - x) / (c - b) if c != b else 1.0


def fuzzify(value, low_params, medium_params, high_params):
    """Fuzzify a crisp value into low/medium/high membership degrees."""
    return {
        'low': triangular_mf(value, *low_params),
        'medium': triangular_mf(value, *medium_params),
        'high': triangular_mf(value, *high_params),
    }


def defuzzify(priority_strengths):
    """Defuzzify using centroid-like approach to get final priority."""
    # Weighted centroid
    values = {'low': 2.0, 'medium': 5.0, 'high': 8.0}
    numerator = sum(priority_strengths[k] * values[k] for k in values)
    denominator = sum(priority_strengths.values())
    if denominator == 0:
        return 5.0  # default to medium
    return numerator / denominator


def compute_priority(urgency, frequency, impact):
    """
    Compute complaint priority using fuzzy logic.
    
    Args:
        urgency:   float 0-10 (how urgent the complaint is)
        frequency: float 0-10 (how often the issue has been reported)
        impact:    float 0-10 (how many people are affected)
    
    Returns:
        dict with 'priority' ('low'/'medium'/'high'), 'score' (0-10), 'label'
    """
    # Membership function parameters (a, b, c) for triangular MF
    low_mf    = (0, 0, 4)
    medium_mf = (2, 5, 8)
    high_mf   = (6, 10, 10)

    # Fuzzify inputs
    u = fuzzify(urgency, low_mf, medium_mf, high_mf)
    f = fuzzify(frequency, low_mf, medium_mf, high_mf)
    i = fuzzify(impact, low_mf, medium_mf, high_mf)

    # Fuzzy rules (simplified)
    # Rule 1: IF urgency is high OR impact is high THEN priority is high
    # Rule 2: IF urgency is medium AND frequency is medium THEN priority is medium
    # Rule 3: IF urgency is low AND frequency is low AND impact is low THEN priority is low
    # Rule 4: IF frequency is high THEN priority is high
    # Rule 5: IF impact is medium THEN priority is medium

    priority_strengths = {
        'high': max(u['high'], i['high'], f['high'],
                    min(u['medium'], i['high']),
                    min(u['high'], f['medium'])),
        'medium': max(min(u['medium'], f['medium']),
                      i['medium'],
                      min(u['low'], f['high']),
                      min(u['medium'], i['medium'])),
        'low': max(min(u['low'], f['low'], i['low']),
                   min(u['low'], i['low']),
                   min(f['low'], i['low'])),
    }

    # Defuzzify
    score = defuzzify(priority_strengths)

    # Map score to label
    if score >= 6.5:
        priority = 'high'
    elif score >= 3.5:
        priority = 'medium'
    else:
        priority = 'low'

    label_map = {'low': 'Low Priority', 'medium': 'Medium Priority', 'high': 'High Priority'}

    return {
        'priority': priority,
        'score': round(score, 2),
        'label': label_map[priority],
        'memberships': {
            'urgency': u,
            'frequency': f,
            'impact': i,
        },
        'rule_strengths': priority_strengths,
    }


if __name__ == '__main__':
    test_cases = [
        (9, 7, 8),  # All high
        (3, 2, 3),  # All low
        (5, 5, 5),  # All medium
        (8, 2, 3),  # Urgent but low frequency/impact
        (2, 9, 7),  # Low urgency but high frequency/impact
    ]
    for urgency, frequency, impact in test_cases:
        result = compute_priority(urgency, frequency, impact)
        print(f"Urgency={urgency}, Frequency={frequency}, Impact={impact}")
        print(f"  → {result['label']} (score: {result['score']})\n")
