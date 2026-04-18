"""
Routing Engine - Automatically routes complaints to the correct department.
Returns department + confidence score for transparent auto-assignment.
"""

# Department mapping based on complaint category
DEPARTMENT_MAP = {
    'roads': 'Public Works Department',
    'water': 'Water Supply Department',
    'water supply': 'Water Supply Department',
    'electricity': 'Electricity Board',
    'sanitation': 'Sanitation Department',
    'garbage': 'Sanitation Department',
    'drainage': 'Drainage & Sewage Department',
    'streetlights': 'Municipal Corporation',
    'parks': 'Parks & Recreation Department',
    'noise': 'Environmental Department',
    'public safety': 'Police & Public Safety',
    'health': 'Health Department',
    'education': 'Education Department',
    'other': 'General Administration',
}

# Keyword-based secondary routing (for AI fallback)
KEYWORD_MAP = {
    'pothole': 'Public Works Department',
    'road': 'Public Works Department',
    'bridge': 'Public Works Department',
    'water': 'Water Supply Department',
    'pipe': 'Water Supply Department',
    'leak': 'Water Supply Department',
    'power': 'Electricity Board',
    'electric': 'Electricity Board',
    'blackout': 'Electricity Board',
    'garbage': 'Sanitation Department',
    'waste': 'Sanitation Department',
    'trash': 'Sanitation Department',
    'sewer': 'Drainage & Sewage Department',
    'drain': 'Drainage & Sewage Department',
    'flood': 'Drainage & Sewage Department',
    'light': 'Municipal Corporation',
    'lamp': 'Municipal Corporation',
    'park': 'Parks & Recreation Department',
    'garden': 'Parks & Recreation Department',
    'noise': 'Environmental Department',
    'pollution': 'Environmental Department',
}


def route_complaint(category, description=''):
    """Returns the department name and confidence score for a complaint."""
    category_clean = (category or '').lower().strip()

    # Direct match = high confidence
    if category_clean in DEPARTMENT_MAP:
        return DEPARTMENT_MAP[category_clean]

    # Keyword-based fallback from description
    desc_lower = (description or '').lower()
    for keyword, dept in KEYWORD_MAP.items():
        if keyword in desc_lower:
            return dept

    return 'General Administration'


def route_complaint_detailed(category, description=''):
    """Returns department + confidence score + auto-routed flag."""
    category_clean = (category or '').lower().strip()

    # Direct category match -> high confidence
    if category_clean in DEPARTMENT_MAP:
        return {
            'department': DEPARTMENT_MAP[category_clean],
            'confidence': 0.95,
            'auto_routed': True,
            'method': 'category_match',
        }

    # Keyword-based from description -> medium confidence
    desc_lower = (description or '').lower()
    for keyword, dept in KEYWORD_MAP.items():
        if keyword in desc_lower:
            return {
                'department': dept,
                'confidence': 0.70,
                'auto_routed': True,
                'method': 'keyword_match',
            }

    # Fallback -> low confidence
    return {
        'department': 'General Administration',
        'confidence': 0.30,
        'auto_routed': False,
        'method': 'fallback',
    }
