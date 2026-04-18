import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();

  int _unreadCount = 0;
  bool _isSubmitPressed = false;
  bool _isCasesPressed = false;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
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

      final notifications = await _apiService.getNotifications();
      final unread = notifications.where((notification) {
        if (notification.isRead) return false;
        final relatedId = (notification.relatedComplaintId ?? '').trim();
        if (relatedId.isEmpty) return true;
        return complaintIds.contains(relatedId);
      }).length;

      if (!mounted) return;
      setState(() {
        _unreadCount = unread;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _unreadCount = 0;
      });
    }
  }

  Future<void> _openNotifications() async {
    await context.push('/notifications');
    if (!mounted) return;
    await _loadUnreadCount();
  }

  Future<void> _handleNavTap(int index) async {
    if (index == 1) {
      context.go('/submit-complaint');
      return;
    }
    if (index == 2) {
      context.go('/my-complaints');
      return;
    }
    if (index == 3) {
      await _openNotifications();
    }
  }

  Widget _buildUpdatesIcon() {
    final badgeText = _unreadCount > 99 ? '99+' : '$_unreadCount';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications),
        if (_unreadCount > 0)
          Positioned(
            right: -8,
            top: -7,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Center(
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF0a0e27), const Color(0xFF1a1f3a)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Welcome!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () async {
                        await _authService.logout();
                        if (context.mounted) context.go('/role-selection');
                      },
                      icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => context.go('/submit-complaint'),
                  onTapDown: (_) => setState(() => _isSubmitPressed = true),
                  onTapCancel: () => setState(() => _isSubmitPressed = false),
                  onTapUp: (_) => setState(() => _isSubmitPressed = false),
                  child: AnimatedScale(
                    scale: _isSubmitPressed ? 0.985 : 1,
                    duration: const Duration(milliseconds: 120),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(
                                alpha: _isSubmitPressed ? 0.35 : 0.2),
                            blurRadius: _isSubmitPressed ? 16 : 10,
                            spreadRadius: _isSubmitPressed ? 1.2 : 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(Icons.add_circle_outline,
                              color: Colors.white),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('File Complaint',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                Text('Report a new issue',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 204),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.go('/my-complaints'),
                  onTapDown: (_) => setState(() => _isCasesPressed = true),
                  onTapCancel: () => setState(() => _isCasesPressed = false),
                  onTapUp: (_) => setState(() => _isCasesPressed = false),
                  child: AnimatedScale(
                    scale: _isCasesPressed ? 0.985 : 1,
                    duration: const Duration(milliseconds: 120),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withValues(
                                alpha: _isCasesPressed ? 0.35 : 0.2),
                            blurRadius: _isCasesPressed ? 16 : 10,
                            spreadRadius: _isCasesPressed ? 1.2 : 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(Icons.folder_open, color: Colors.white),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('My Cases',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                Text('Track your complaints',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 204),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Submit'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.folder), label: 'Cases'),
          BottomNavigationBarItem(
            icon: _buildUpdatesIcon(),
            label: 'Updates',
          ),
        ],
        currentIndex: 0,
        onTap: _handleNavTap,
      ),
    );
  }
}
