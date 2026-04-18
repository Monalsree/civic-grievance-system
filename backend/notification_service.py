"""
Notification Service - Manages in-app status notifications for complaints.
"""

# In-memory notification store (replace with DB in production)
_notifications = []

def create_notification(complaint_id, message, notif_type='info'):
    """Create a new notification for a complaint."""
    import datetime
    notification = {
        'complaint_id': complaint_id,
        'message': message,
        'type': notif_type,
        'read': False,
        'created_at': datetime.datetime.now().isoformat(),
    }
    _notifications.append(notification)
    return notification

def get_notifications(complaint_id=None):
    """Get notifications, optionally filtered by complaint_id."""
    if complaint_id:
        return [n for n in _notifications if n['complaint_id'] == complaint_id]
    return list(_notifications)

def notify_status_change(complaint_id, old_status, new_status):
    """Send a notification when a complaint status changes."""
    message = f"Complaint {complaint_id}: status changed from '{old_status}' to '{new_status}'."
    return create_notification(complaint_id, message, notif_type='status_change')
