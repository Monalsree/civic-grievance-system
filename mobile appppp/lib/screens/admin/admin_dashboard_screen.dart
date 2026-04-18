import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  bool _isLoading = true;
  String? _error;

  String _activeFilter = 'all';

  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _allComplaints = [];

  final Set<String> _statusUpdatingIds = <String>{};
  final Set<String> _upvotingIds = <String>{};

  static const List<String> _statusFilters = [
    'all',
    'submitted',
    'assigned',
    'pending',
    'resolved',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> summary = <String, dynamic>{};
      List<Map<String, dynamic>> complaints = <Map<String, dynamic>>[];
      String? partialError;

      try {
        complaints = await _apiService.getComplaintsRaw();
      } catch (e) {
        partialError = _cleanError(e);
      }

      try {
        summary = await _apiService.getAnalyticsSummary();
      } catch (e) {
        partialError ??= _cleanError(e);
      }

      complaints.sort((a, b) {
        final aScore = (a['fuzzy_priority_score'] is num)
            ? (a['fuzzy_priority_score'] as num).toDouble()
            : 0;
        final bScore = (b['fuzzy_priority_score'] is num)
            ? (b['fuzzy_priority_score'] as num).toDouble()
            : 0;

        final scoreCompare = bScore.compareTo(aScore);
        if (scoreCompare != 0) return scoreCompare;

        final aDate = DateTime.tryParse((a['created_at'] ?? '').toString());
        final bDate = DateTime.tryParse((b['created_at'] ?? '').toString());
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _allComplaints = complaints;
        _error = complaints.isEmpty ? partialError : null;
      });

      if (complaints.isNotEmpty && partialError != null) {
        _showToast(
          'Some analytics could not be loaded. Complaints are shown.',
          _ToastType.info,
        );
      }
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

  bool _statusMatchesFilter(String rawStatus, String filter) {
    if (filter == 'all') return true;

    final status = rawStatus.toLowerCase();
    if (filter == 'submitted') {
      return status == 'submitted';
    }
    if (filter == 'pending') {
      return status == 'pending' ||
          status == 'in-progress' ||
          status == 'ongoing';
    }

    return status == filter;
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  double _asDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? fallback;
  }

  String _topCategoryInsight() {
    if (_allComplaints.isEmpty) return 'No category trend yet';

    final counts = <String, int>{};
    for (final complaint in _allComplaints) {
      final category = _safeText(complaint['category'], fallback: 'Other');
      counts[category] = (counts[category] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.first;
    return 'Top category: ${top.key} (${top.value})';
  }

  String _statusForDropdown(String rawStatus) {
    final status = rawStatus.toLowerCase();
    if (status == 'pending') return 'submitted';
    if (status == 'ongoing' || status == 'in-progress') return 'in-progress';

    if (_statusFilters.contains(status)) {
      return status;
    }
    return 'submitted';
  }

  List<Map<String, dynamic>> get _filteredComplaints {
    return _allComplaints.where((complaint) {
      final status = (complaint['status'] ?? 'submitted').toString();
      return _statusMatchesFilter(status, _activeFilter);
    }).toList();
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Color _statusColor(String status) {
    final normalized = _statusForDropdown(status);
    switch (normalized) {
      case 'resolved':
        return const Color(0xFF10B981);
      case 'assigned':
        return const Color(0xFF3B82F6);
      case 'in-progress':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '-';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return _dateFormat.format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  String _safeText(dynamic value, {String fallback = '-'}) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  void _showToast(String message, _ToastType type) {
    if (!mounted) return;

    final color = switch (type) {
      _ToastType.success => const Color(0xFF16A34A),
      _ToastType.error => const Color(0xFFDC2626),
      _ToastType.info => const Color(0xFF2563EB),
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
        ),
      );
  }

  Future<void> _updateComplaintStatus(
    String complaintId,
    String newStatus, {
    String? notes,
  }) async {
    if (_statusUpdatingIds.contains(complaintId)) return;

    setState(() {
      _statusUpdatingIds.add(complaintId);
    });

    try {
      await _apiService.updateAdminComplaintStatus(
        complaintId: complaintId,
        status: newStatus,
        notes: (notes ?? '').trim().isEmpty
            ? 'Status updated by admin from dashboard.'
            : notes!.trim(),
      );

      _showToast(
        'Status updated to ${_readableStatus(newStatus)}',
        _ToastType.success,
      );
      await _loadDashboard();
    } catch (e) {
      _showToast(_cleanError(e), _ToastType.error);
    } finally {
      if (!mounted) return;
      setState(() {
        _statusUpdatingIds.remove(complaintId);
      });
    }
  }

  String _readableStatus(String status) {
    if (status == 'in-progress') return 'In Progress';
    return '${status[0].toUpperCase()}${status.substring(1)}';
  }

  Future<void> _openStatusUpdateDialog(Map<String, dynamic> complaint) async {
    final complaintId = _safeText(complaint['id']);
    var selectedStatus = _statusForDropdown(
        _safeText(complaint['status'], fallback: 'submitted'));
    final notesController = TextEditingController();

    try {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('Update Status • $complaintId'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'New Status',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'submitted',
                          child: Text('Submitted'),
                        ),
                        DropdownMenuItem(
                          value: 'assigned',
                          child: Text('Assigned'),
                        ),
                        DropdownMenuItem(
                          value: 'in-progress',
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(
                          value: 'resolved',
                          child: Text('Resolved'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Status Note (optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await _updateComplaintStatus(
                        complaintId,
                        selectedStatus,
                        notes: notesController.text,
                      );
                    },
                    child: const Text('Update'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      notesController.dispose();
    }
  }

  Future<void> _upvoteComplaint(String complaintId) async {
    if (_upvotingIds.contains(complaintId)) return;

    final username = _authService.currentUser?.username ?? '';
    if (username.isEmpty) {
      _showToast('Admin user not found. Please login again.', _ToastType.error);
      return;
    }

    setState(() {
      _upvotingIds.add(complaintId);
    });

    try {
      final response = await _apiService.upvoteComplaint(
        complaintId: complaintId,
        username: username,
      );
      _showToast(
        'Upvoted successfully. Total votes: ${response['upvotes'] ?? 0}',
        _ToastType.success,
      );
      await _loadDashboard();
    } catch (e) {
      final message = _cleanError(e);
      if (message.toLowerCase().contains('already upvoted')) {
        _showToast('You already upvoted this complaint.', _ToastType.info);
      } else {
        _showToast(message, _ToastType.error);
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _upvotingIds.remove(complaintId);
      });
    }
  }

  Future<void> _openComplaintDetails(String complaintId) async {
    try {
      final detail = await _apiService.getComplaintDetailsRaw(complaintId);
      final history = (detail['history'] as List<dynamic>? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('Complaint ${_safeText(detail['id'])}'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow('Category', _safeText(detail['category'])),
                    _detailRow('Department', _safeText(detail['department'])),
                    _detailRow('Location', _safeText(detail['location'])),
                    _detailRow('Priority', _safeText(detail['priority'])),
                    _detailRow('Status', _safeText(detail['status'])),
                    _detailRow('Upvotes', _safeText(detail['upvotes'])),
                    _detailRow('Fuzzy Score',
                        _safeText(detail['fuzzy_priority_score'])),
                    _detailRow(
                        'Submitted On', _formatDate(detail['created_at'])),
                    const SizedBox(height: 8),
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(_safeText(detail['description'])),
                    const SizedBox(height: 14),
                    const Text(
                      'Status Timeline',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    if (history.isEmpty)
                      const Text('No status history available.')
                    else
                      ...history.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${_safeText(entry['status'])}  •  '
                            '${_formatDate(entry['changed_at'])}'
                            '${_safeText(entry['notes']).trim() == '-' ? '' : '  •  ${_safeText(entry['notes'])}'}',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _showToast(_cleanError(e), _ToastType.error);
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              Text(
                'Welcome, ${_authService.currentUser?.name ?? 'Admin'}',
                style: const TextStyle(
                  color: Color(0xFFA0AEC0),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: _loadDashboard,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
              ),
              IconButton(
                onPressed: () async {
                  await _authService.logout();
                  if (context.mounted) {
                    context.go('/role-selection');
                  }
                },
                icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                tooltip: 'Logout',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.push('/admin-analytics'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                'Insights and Map',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalCount =
        _asInt(_summary['total'], fallback: _allComplaints.length);
    final openCount = _allComplaints
        .where((c) => !_statusMatchesFilter(
            (c['status'] ?? 'submitted').toString(), 'resolved'))
        .length;
    final resolvedCount = _allComplaints
        .where((c) => _statusMatchesFilter(
            (c['status'] ?? 'submitted').toString(), 'resolved'))
        .length;
    final highPriorityCount = _allComplaints
        .where((c) => (c['priority'] ?? '').toString().toLowerCase() == 'high')
        .length;

    final resolutionRate = _asDouble(
      _summary['resolution_rate'],
      fallback: totalCount == 0 ? 0 : (resolvedCount * 100 / totalCount),
    );
    final openShare = totalCount == 0 ? 0 : (openCount * 100 / totalCount);
    final highShare =
        totalCount == 0 ? 0 : (highPriorityCount * 100 / totalCount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          SizedBox(
            height: 102,
            child: Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Total',
                    totalCount.toString(),
                    _topCategoryInsight(),
                    const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    'Open Cases',
                    openCount.toString(),
                    '${openShare.toStringAsFixed(1)}% of all complaints',
                    const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 102,
            child: Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Resolution',
                    '${resolutionRate.toStringAsFixed(1)}%',
                    '$resolvedCount resolved so far',
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    'High Priority',
                    highPriorityCount.toString(),
                    '${highShare.toStringAsFixed(1)}% high severity',
                    const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 10),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _statusFilters.map((filter) {
          final isActive = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isActive,
              label: Text(
                filter == 'all'
                    ? 'All'
                    : filter == 'pending'
                        ? 'Pending'
                        : '${filter[0].toUpperCase()}${filter.substring(1)}',
              ),
              onSelected: (_) {
                setState(() {
                  _activeFilter = filter;
                });
              },
              selectedColor: const Color(0xFF111111),
              labelStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: const Color(0xFF000000),
              side: BorderSide(
                color: isActive
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF334155),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final id = _safeText(complaint['id']);
    final category = _safeText(complaint['category']);
    final location = _safeText(complaint['location']);
    final department = _safeText(complaint['department']);
    final priority = _safeText(complaint['priority'], fallback: 'medium');
    final status = _safeText(complaint['status'], fallback: 'submitted');
    final upvotes = _safeText(complaint['upvotes'], fallback: '0');
    final fuzzyScore =
        _safeText(complaint['fuzzy_priority_score'], fallback: '-');

    final statusBusy = _statusUpdatingIds.contains(id);
    final upvoteBusy = _upvotingIds.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  id,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _priorityColor(priority).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    color: _priorityColor(priority),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _readableStatus(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$category  •  $location',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Department: $department',
            style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Fuzzy Score: $fuzzyScore',
            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Created: ${_formatDate(complaint['created_at'])}',
            style: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: upvoteBusy ? null : () => _upvoteComplaint(id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                icon: upvoteBusy
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.thumb_up_alt_outlined, size: 14),
                label: Text(upvotes),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _openStatusUpdateDialog(complaint),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _openComplaintDetails(id),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                  foregroundColor: Colors.white,
                ),
                child: const Text('View'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Color(0xFFEF4444), size: 40),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadDashboard,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredComplaints;

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          _buildStatsCards(),
          const SizedBox(height: 12),
          _buildFilters(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Complaints (${filtered.length})',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: filtered.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'No complaints found for the selected filter.',
                      style: TextStyle(color: Color(0xFFCBD5E1)),
                    ),
                  )
                : Column(
                    children:
                        filtered.map((c) => _buildComplaintCard(c)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildNavigation(),
              const SizedBox(height: 8),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ToastType { success, error, info }
