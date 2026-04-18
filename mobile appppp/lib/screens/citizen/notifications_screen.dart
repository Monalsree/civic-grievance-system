import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/analytics_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();

  bool _isLoading = true;
  String? _error;

  List<UserNotification> _notifications = [];
  Set<String> _trackedComplaintIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _authService.currentUser;
      final complaints = await _apiService.getCitizenComplaints(
        phone: user?.phone,
        username: user?.username,
      );
      final complaintIds = complaints
          .map((item) => (item['id'] ?? '').toString())
          .where((value) => value.isNotEmpty)
          .toSet();

      final rawNotifications = await _apiService.getNotifications();

      final filtered = rawNotifications.where((notification) {
        final relatedId = (notification.relatedComplaintId ?? '').toString();
        if (relatedId.isEmpty) {
          return true;
        }
        return complaintIds.contains(relatedId);
      }).toList();

      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() {
        _trackedComplaintIds = complaintIds;
        _notifications = filtered;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _cleanError(e);
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _cleanError(Object e) {
    final text = e.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring(11).trim();
    }
    return text;
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'resolved':
        return Icons.check_circle;
      case 'status_change':
        return Icons.refresh;
      case 'message':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'resolved':
        return const Color(0xFF16A34A);
      case 'status_change':
        return const Color(0xFF2563EB);
      case 'message':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  String _formatDate(DateTime createdAt) {
    return '${createdAt.day.toString().padLeft(2, '0')} '
        '${_monthName(createdAt.month)} '
        '${createdAt.year}, '
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  Widget _buildCard(UserNotification notification) {
    final color = _colorForType(notification.type);
    final icon = _iconForType(notification.type);
    final complaintId = notification.relatedComplaintId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: complaintId == null
            ? null
            : () => context.push('/my-complaints?q=$complaintId'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _formatDate(notification.createdAt),
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        if (complaintId != null)
                          Text(
                            'Complaint $complaintId',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0e27),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/citizen-home'),
        ),
        title: const Text(
          'Updates',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadUpdates,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0a0e27), Color(0xFF1a1f3a)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                  ),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFEF4444), size: 42),
                            const SizedBox(height: 10),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _loadUpdates,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUpdates,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.notifications_active,
                                    color: Colors.white),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Live updates for ${_trackedComplaintIds.length} tracked complaint${_trackedComplaintIds.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_notifications.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No live updates yet',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'You will see status changes and admin messages here after your complaints receive updates.',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._notifications.map(_buildCard),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
