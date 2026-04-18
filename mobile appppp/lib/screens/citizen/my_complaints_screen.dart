import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/voice_input_button.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  final Set<String> _expandedComplaintIds = <String>{};

  List<Map<String, dynamic>> _myComplaints = [];
  Map<String, dynamic>? _selectedComplaint;

  bool _isLoading = true;
  bool _isSearching = false;

  String? _loadError;
  String? _searchError;

  Timer? _shimmerTimer;
  bool _shimmerPhase = false;
  SearchMode _searchMode = SearchMode.auto;

  @override
  void initState() {
    super.initState();
    _loadMyComplaints();
    _shimmerTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      setState(() {
        _shimmerPhase = !_shimmerPhase;
      });
    });

    final initial = widget.initialQuery?.trim();
    if (initial != null && initial.isNotEmpty) {
      _searchController.text = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchComplaint();
      });
    }
  }

  Future<void> _loadMyComplaints() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final user = _authService.currentUser;
      final complaints = await _apiService.getCitizenComplaints(
        phone: user?.phone,
        username: user?.username,
      );

      if (!mounted) return;
      setState(() {
        _myComplaints = complaints;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = _cleanError(e);
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchComplaint() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _showToast(
          'Choose a search option and enter your value.', ToastKind.error);
      return;
    }

    if (_searchMode == SearchMode.phone) {
      final digitsOnly = query.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length < 10) {
        _showToast(
            'Phone mode expects a valid 10-digit number.', ToastKind.error);
        return;
      }
    }

    if (_searchMode == SearchMode.complaintId &&
        !query.toUpperCase().startsWith('CG')) {
      _showToast(
          'Complaint ID mode expects values like CG2026....', ToastKind.error);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final searchResponse = await _apiService.searchCitizenComplaints(query);
      final results = (searchResponse['results'] as List<dynamic>? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (results.isEmpty) {
        if (!mounted) return;
        setState(() {
          _selectedComplaint = null;
          _searchError =
              'No complaint found. Verify the Complaint ID or phone number and try again.';
        });
        return;
      }

      final complaintId = (results.first['id'] ?? '').toString();
      if (complaintId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _selectedComplaint = null;
          _searchError = 'Complaint details could not be loaded.';
        });
        return;
      }

      final detail = await _apiService.getCitizenComplaintDetails(complaintId);

      if (!mounted) return;
      setState(() {
        _selectedComplaint = detail;
      });
    } catch (e) {
      final message = _cleanError(e);
      if (!mounted) return;
      setState(() {
        _selectedComplaint = null;
        _searchError = message.contains('No complaints found')
            ? 'No complaint found. Verify the Complaint ID or phone number and try again.'
            : message;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _openComplaintDetail(String complaintId) async {
    try {
      final detail = await _apiService.getCitizenComplaintDetails(complaintId);
      if (!mounted) return;
      setState(() {
        _selectedComplaint = detail;
        _searchError = null;
      });
    } catch (e) {
      _showToast(_cleanError(e), ToastKind.error);
    }
  }

  Future<void> _upvoteComplaint(String complaintId) async {
    final username = _authService.currentUser?.username ?? '';
    if (username.isEmpty) {
      _showToast('Login required to upvote.', ToastKind.error);
      return;
    }

    try {
      final response = await _apiService.upvoteCitizenComplaint(
        complaintId: complaintId,
        username: username,
      );

      _showToast(
        'Upvoted successfully. Total upvotes: ${response['upvotes'] ?? 0}',
        ToastKind.success,
      );

      await _loadMyComplaints();
      if (_selectedComplaint != null &&
          (_selectedComplaint!['id'] ?? '').toString() == complaintId) {
        await _openComplaintDetail(complaintId);
      }
    } catch (e) {
      final message = _cleanError(e);
      if (message.toLowerCase().contains('already upvoted')) {
        _showToast('You already upvoted this complaint.', ToastKind.info);
      } else {
        _showToast(message, ToastKind.error);
      }
    }
  }

  Future<void> _refreshAll() async {
    await _loadMyComplaints();
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      await _searchComplaint();
    }
  }

  void _newSearch() {
    setState(() {
      _searchController.clear();
      _searchError = null;
      _selectedComplaint = null;
    });
  }

  String _cleanError(Object e) {
    final text = e.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring(11).trim();
    }
    return text;
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return '-';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a')
          .format(DateTime.parse(rawDate.toString()).toLocal());
    } catch (_) {
      return rawDate.toString();
    }
  }

  String _priorityText(Map<String, dynamic> complaint) {
    final priority =
        (complaint['priority'] ?? 'medium').toString().toLowerCase();
    return priority.toUpperCase();
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'low':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFFD97706);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return const Color(0xFF16A34A);
      case 'assigned':
        return const Color(0xFF2563EB);
      case 'in-progress':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _statusLabel(String status) {
    final cleaned = status.toLowerCase();
    if (cleaned.isEmpty) return 'Submitted';
    if (cleaned == 'in-progress') return 'In Progress';
    return '${cleaned[0].toUpperCase()}${cleaned.substring(1)}';
  }

  double _statusProgress(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return 1.0;
      case 'in-progress':
        return 0.72;
      case 'assigned':
        return 0.45;
      default:
        return 0.2;
    }
  }

  IconData _departmentIcon(String department, String category) {
    final key = '$department $category'.toLowerCase();
    if (key.contains('electric')) return Icons.flash_on_rounded;
    if (key.contains('water')) return Icons.water_drop_rounded;
    if (key.contains('road')) return Icons.add_road_rounded;
    if (key.contains('sanitation') || key.contains('garbage')) {
      return Icons.cleaning_services_rounded;
    }
    if (key.contains('drainage')) return Icons.waves_rounded;
    if (key.contains('park')) return Icons.park_rounded;
    return Icons.account_balance_rounded;
  }

  String _categoryWithEmoji(String category) {
    final value = category.toLowerCase();
    if (value.contains('electric')) return 'Electricity ⚡';
    if (value.contains('water')) return 'Water 💧';
    if (value.contains('road')) return 'Roads 🛣️';
    if (value.contains('sanitation')) return 'Sanitation 🧹';
    if (value.contains('drainage')) return 'Drainage 🌧️';
    if (value.contains('park')) return 'Parks 🌳';
    return category;
  }

  String _humanStatusMessage(Map<String, dynamic> complaint) {
    final status =
        (complaint['status'] ?? 'submitted').toString().toLowerCase();
    final department =
        (complaint['department'] ?? 'Concerned Department').toString();
    if (status == 'resolved') {
      return 'Issue resolved. Thank you for helping improve your city.';
    }
    if (status == 'in-progress') {
      return 'Work is in progress by $department.';
    }
    if (status == 'assigned') {
      return 'Assigned to $department.';
    }
    return 'We received your complaint and will assign it shortly.';
  }

  String _estimatedResolution(Map<String, dynamic> complaint) {
    final explicit = (complaint['estimatedResolution'] ?? '').toString().trim();
    if (explicit.isNotEmpty) return explicit;

    final status = (complaint['status'] ?? '').toString().toLowerCase();
    if (status == 'resolved') return 'Resolved';

    final priority =
        (complaint['priority'] ?? 'medium').toString().toLowerCase();
    if (priority == 'high') return 'Estimated: 24-48 hours';
    if (priority == 'low') return 'Estimated: 5-7 business days';
    return 'Estimated: 3-5 business days';
  }

  void _showToast(String message, ToastKind kind) {
    if (!mounted) return;

    final color = switch (kind) {
      ToastKind.success => const Color(0xFF16A34A),
      ToastKind.error => const Color(0xFFDC2626),
      ToastKind.info => const Color(0xFF2563EB),
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

  Widget _buildComplaintListCard(Map<String, dynamic> complaint) {
    final id = (complaint['id'] ?? '-').toString();
    final status = (complaint['status'] ?? 'submitted').toString();
    final priority = (complaint['priority'] ?? 'medium').toString();
    final category = (complaint['category'] ?? '-').toString();
    final department = (complaint['department'] ?? '-').toString();
    final isExpanded = _expandedComplaintIds.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedComplaintIds.remove(id);
            } else {
              _expandedComplaintIds.add(id);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      id,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              _priorityColor(priority).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _priorityText(complaint),
                          style: TextStyle(
                            color: _priorityColor(priority),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _PulsingStatusChip(
                        statusText: _statusLabel(status),
                        color: _statusColor(status),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _departmentIcon(department, category),
                    size: 16,
                    color: const Color(0xFF4F46E5),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_categoryWithEmoji(category)}  •  ${complaint['location'] ?? '-'}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Submitted: ${_formatDate(complaint['created_at'])}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                _humanStatusMessage(complaint),
                style: const TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 240),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.72),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: _statusColor(status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _statusProgress(status),
                        minHeight: 7,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_statusColor(status)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => _openComplaintDetail(id),
                        icon: const Icon(Icons.timeline_rounded, size: 16),
                        label: const Text('View timeline'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upvotes: ${complaint['upvotes'] ?? 0}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _upvoteComplaint(id),
                    icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                    label: const Text('Upvote'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(Map<String, dynamic> complaint) {
    final status = (complaint['status'] ?? 'submitted').toString();
    final priority = (complaint['priority'] ?? 'medium').toString();

    final history = (complaint['history'] as List<dynamic>? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final historyByStatus = <String, Map<String, dynamic>>{};
    for (final entry in history) {
      final key = (entry['status'] ?? '').toString();
      if (key.isNotEmpty && !historyByStatus.containsKey(key)) {
        historyByStatus[key] = entry;
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Complaint Details',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _priorityColor(priority).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _priorityText(complaint),
                      style: TextStyle(
                        color: _priorityColor(priority),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _statusColor(status),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          _detailRow('ID', (complaint['id'] ?? '-').toString()),
          _detailRow('Category', (complaint['category'] ?? '-').toString()),
          _detailRow('Department', (complaint['department'] ?? '-').toString()),
          _detailRow('Location', (complaint['location'] ?? '-').toString()),
          _buildLocationPreviewCard(complaint),
          _detailRow('Submitted On', _formatDate(complaint['created_at'])),
          _detailRow(
              'Description', (complaint['description'] ?? '-').toString()),
          _detailRow('Estimated Resolution', _estimatedResolution(complaint)),
          const SizedBox(height: 10),
          _buildFuzzyScoreCard(complaint),
          const SizedBox(height: 14),
          const Text(
            'Status Timeline',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          _buildTimeline(
            currentStatus: status,
            createdAt: complaint['created_at'],
            historyByStatus: historyByStatus,
          ),
          if (history.any((entry) =>
              (entry['notes'] ?? '').toString().trim().isNotEmpty)) ...[
            const SizedBox(height: 10),
            const Text(
              'Status Notes',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...history
                .where((entry) =>
                    (entry['notes'] ?? '').toString().trim().isNotEmpty)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${entry['status']}: ${entry['notes']}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildFuzzyScoreCard(Map<String, dynamic> complaint) {
    String formatScore(dynamic value) {
      if (value == null) return '-';
      if (value is num) return value.toStringAsFixed(1);
      return value.toString();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Fuzzy Scores  •  '
        'Urgency: ${formatScore(complaint['urgency_score'])}  '
        'Frequency: ${formatScore(complaint['frequency_score'])}  '
        'Impact: ${formatScore(complaint['impact_score'])}  '
        'Final: ${formatScore(complaint['fuzzy_priority_score'])}',
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTimeline({
    required String currentStatus,
    required dynamic createdAt,
    required Map<String, Map<String, dynamic>> historyByStatus,
  }) {
    final stages = <String>['submitted', 'assigned', 'in-progress', 'resolved'];
    final currentIndex = stages.indexOf(currentStatus.toLowerCase());

    return Column(
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final isReached = currentIndex >= index;
        final stageHistory = historyByStatus[stage];

        String timeText;
        if (stageHistory != null && stageHistory['changed_at'] != null) {
          timeText = _formatDate(stageHistory['changed_at']);
        } else if (stage == 'submitted') {
          timeText = _formatDate(createdAt);
        } else {
          timeText = 'Pending';
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isReached
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFD1D5DB),
                  ),
                ),
                if (index != stages.length - 1)
                  Container(
                    width: 2,
                    height: 26,
                    color: isReached
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFD1D5DB),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatStage(stage),
                      style: TextStyle(
                        color: isReached ? Colors.black : Colors.black45,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeText,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  String _formatStage(String status) {
    return _statusLabel(status);
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Widget _buildLocationPreviewCard(Map<String, dynamic> complaint) {
    final location = (complaint['location'] ?? '-').toString();
    final latitude = _asDouble(complaint['latitude'] ?? complaint['lat']);
    final longitude = _asDouble(complaint['longitude'] ?? complaint['lng']);

    if (latitude == null || longitude == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$location\nMap preview appears when coordinates are available.',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final center = LatLng(latitude, longitude);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'civic_grievance_system',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 42,
                      height: 42,
                      child: const Icon(
                        Icons.location_on,
                        size: 34,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              '📍 $location',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No complaint found 😕',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchError ??
                'Please verify your Complaint ID or phone number and try again.',
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 10),
          const Text(
            'Guidance:',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text('- Use the exact complaint ID received after submission.'),
          const Text(
              '- You can also search using the same phone number used while filing.'),
          const Text('- Use Refresh to fetch latest updates from server.'),
        ],
      ),
    );
  }

  Widget _buildHowToTrackCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to Track 🙂',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '- Search by Complaint ID for fastest results.',
            style: TextStyle(color: Colors.black87),
          ),
          Text(
            '- You can also search by the phone number used while filing.',
            style: TextStyle(color: Colors.black87),
          ),
          Text(
            '- Tap any complaint card to open full timeline details.',
            style: TextStyle(color: Colors.black87),
          ),
          Text(
            '- Use Refresh to fetch the latest status updates.',
            style: TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _shimmerTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 4,
      itemBuilder: (context, index) {
        final opacity = _shimmerPhase ? 0.48 : 0.74;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 650),
          opacity: opacity,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          Container(height: 12, color: const Color(0xFFE5E7EB)),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 70,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(height: 10, color: const Color(0xFFE5E7EB)),
                const SizedBox(height: 8),
                Container(height: 10, color: const Color(0xFFE5E7EB)),
                const SizedBox(height: 12),
                const LinearProgressIndicator(minHeight: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  String _searchHintByMode() {
    switch (_searchMode) {
      case SearchMode.complaintId:
        return '🆔 Enter Complaint ID (e.g., CG2026...)';
      case SearchMode.phone:
        return '📱 Enter Phone Number (10 digits)';
      case SearchMode.auto:
        return '🔎 Enter Complaint ID or phone number';
    }
  }

  Widget _buildSearchModeChip({
    required SearchMode mode,
    required String label,
  }) {
    final selected = _searchMode == mode;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) {
        setState(() {
          _searchMode = mode;
        });
      },
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFF3F4F6),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF334155),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(
        color: selected ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/citizen-home'),
        ),
        title: const Text(
          'Track Complaints',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF60A5FA).withValues(alpha: 0.24),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -120,
              right: -70,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFF59E0B).withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Select Search Option:',
                                    style: TextStyle(
                                      color: Color(0xFF334155),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _buildSearchModeChip(
                                            mode: SearchMode.auto,
                                            label: '🔎 Auto',
                                          ),
                                          const SizedBox(width: 6),
                                          _buildSearchModeChip(
                                            mode: SearchMode.complaintId,
                                            label: '🆔 Complaint ID',
                                          ),
                                          const SizedBox(width: 6),
                                          _buildSearchModeChip(
                                            mode: SearchMode.phone,
                                            label: '📱 Phone',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      style:
                                          const TextStyle(color: Colors.black),
                                      decoration: InputDecoration(
                                        hintText: _searchHintByMode(),
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                        suffixIcon: VoiceInputButton(
                                          controller: _searchController,
                                          idleColor: const Color(0xFF2563EB),
                                        ),
                                      ),
                                      onSubmitted: (_) => _searchComplaint(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed: _isSearching
                                          ? null
                                          : _searchComplaint,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF2563EB),
                                        elevation: 2,
                                      ),
                                      child: _isSearching
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'Search 🔍',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _refreshAll,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Refresh 🔄'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _newSearch,
                                      icon: const Icon(Icons.search_off),
                                      label: const Text('New Search ✨'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: _isLoading
                            ? _buildLoadingSkeleton()
                            : ListView(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                children: [
                                  const Text(
                                    'My Complaints',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (_loadError != null)
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _loadError!,
                                        style: const TextStyle(
                                          color: Color(0xFF991B1B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else if (_myComplaints.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'No complaints yet 🙂\nSubmit your first complaint to start tracking.',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                    )
                                  else
                                    ..._myComplaints
                                        .map(_buildComplaintListCard),
                                  if (_searchError != null)
                                    _buildNoResultCard(),
                                  if (_selectedComplaint != null)
                                    _buildDetailCard(_selectedComplaint!),
                                  _buildHowToTrackCard(),
                                  const SizedBox(height: 20),
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
    );
  }
}

class _PulsingStatusChip extends StatefulWidget {
  const _PulsingStatusChip({
    required this.statusText,
    required this.color,
  });

  final String statusText;
  final Color color;

  @override
  State<_PulsingStatusChip> createState() => _PulsingStatusChipState();
}

class _PulsingStatusChipState extends State<_PulsingStatusChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final alpha = 0.13 + (_controller.value * 0.16);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.statusText,
            style: TextStyle(
              color: widget.color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

enum ToastKind { success, error, info }

enum SearchMode { auto, complaintId, phone }
