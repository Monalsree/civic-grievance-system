"""
Reports - Aggregated analytics reports API.
"""

from trend_analysis import complaints_by_category, complaints_by_status, complaints_over_time, top_departments  # type: ignore
from response_time import avg_resolution_time, department_performance  # type: ignore


def generate_full_report():
    """Generate a comprehensive analytics report."""
    return {
        'by_category': complaints_by_category(),
        'by_status': complaints_by_status(),
        'daily_trend': complaints_over_time(30),
        'top_departments': top_departments(),
        'resolution_times': avg_resolution_time(),
        'department_performance': department_performance(),
    }


def generate_summary():
    """Generate a short summary report."""
    categories = complaints_by_category()
    statuses = complaints_by_status()
    total = sum(s.get('count', 0) for s in statuses)
    resolved = sum(s.get('count', 0) for s in statuses if s.get('status') == 'resolved')
    pending = total - resolved

    return {
        'total_complaints': total,
        'resolved': resolved,
        'pending': pending,
        'resolution_rate': round(float(resolved) / float(total) * 100, 1) if total > 0 else 0.0,
        'top_category': categories[0] if categories else None,
    }


if __name__ == '__main__':
    import json
    print("📊 Summary Report:")
    print(json.dumps(generate_summary(), indent=2))
    print("\n📊 Full Report:")
    print(json.dumps(generate_full_report(), indent=2))
