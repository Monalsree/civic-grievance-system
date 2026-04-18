import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../services/api_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final _apiService = ApiService();
  static const List<Color> _chartPalette = [
    Color(0xFF4F46E5),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
  ];

  bool _isLoading = true;
  String? _error;

  String _activeSection = 'insights';

  Map<String, dynamic> _summary = {};
  Map<String, dynamic> _insightsData = {};
  Map<String, dynamic> _predictionsData = {};
  List<Map<String, dynamic>> _complaints = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summaryFuture = _apiService.getAnalyticsSummary();
      final insightsFuture = _apiService.getAnalyticsInsights();
      final predictionsFuture = _apiService.getAnalyticsPredictions();
      final complaintsFuture = _apiService.getComplaintsRaw();

      final results = await Future.wait<dynamic>([
        summaryFuture,
        insightsFuture,
        predictionsFuture,
        complaintsFuture,
      ]);

      if (!mounted) return;
      setState(() {
        _summary = Map<String, dynamic>.from(results[0] as Map);
        _insightsData = Map<String, dynamic>.from(results[1] as Map);
        _predictionsData = Map<String, dynamic>.from(results[2] as Map);
        _complaints = List<Map<String, dynamic>>.from(results[3] as List);
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

  String _safeText(dynamic value, {String fallback = '-'}) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
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

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  LatLng _resolveComplaintPosition(Map<String, dynamic> complaint) {
    final latRaw = complaint['latitude'];
    final lngRaw = complaint['longitude'];

    final lat =
        (latRaw is num) ? latRaw.toDouble() : double.tryParse('$latRaw');
    final lng =
        (lngRaw is num) ? lngRaw.toDouble() : double.tryParse('$lngRaw');

    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }

    final location = _safeText(complaint['location'], fallback: 'unknown');
    final codes = location.codeUnits;
    var hashA = 0;
    var hashB = 7;

    for (final c in codes) {
      hashA = (hashA * 31 + c) % 100000;
      hashB = (hashB * 37 + c) % 100000;
    }

    final latitude = 8.0 + (hashA % 2700) / 100.0;
    final longitude = 68.0 + (hashB % 2900) / 100.0;

    return LatLng(latitude, longitude);
  }

  Widget _sectionChip(String key, String label) {
    final isActive = _activeSection == key;

    return ChoiceChip(
      selected: isActive,
      label: Text(label),
      onSelected: (_) {
        setState(() {
          _activeSection = key;
        });
      },
      selectedColor: const Color(0xFF111111),
      backgroundColor: const Color(0xFF000000),
      side: BorderSide(
        color: isActive ? const Color(0xFF60A5FA) : const Color(0xFF334155),
      ),
      labelStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _statCard(String title, String value, String subtitle, Color color) {
    return Container(
      width: 162,
      margin: const EdgeInsets.only(right: 10),
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
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11),
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

  Widget _distributionCard(
    String title,
    List<Map<String, dynamic>> values,
    Color color,
  ) {
    final maxCount = values.isEmpty
        ? 1
        : values
            .map((e) => ((e['count'] as num?) ?? 0).toDouble())
            .reduce(max)
            .toDouble();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (values.isEmpty)
            const Text(
              'No data available',
              style: TextStyle(color: Color(0xFFA0AEC0)),
            )
          else
            ...values.map((entry) {
              final label = _safeText(
                entry['category'] ??
                    entry['status'] ??
                    entry['priority'] ??
                    entry['department'],
              );
              final count = ((entry['count'] as num?) ?? 0).toDouble();
              final ratio = maxCount == 0 ? 0.0 : (count / maxCount);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          count.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: ratio,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _normalizedCategoryData(
    List<Map<String, dynamic>> values, {
    int limit = 6,
  }) {
    final normalized = values
        .map((item) {
          final label = _safeText(item['category'], fallback: 'Other');
          final rawCount = item['count'];
          final count = rawCount is num
              ? rawCount.toDouble()
              : double.tryParse('$rawCount') ?? 0;
          return {
            'label': label,
            'count': count,
          };
        })
        .where((item) => (item['count'] as double) > 0)
        .toList();

    normalized.sort(
      (a, b) => (b['count'] as double).compareTo(a['count'] as double),
    );

    return normalized.take(limit).toList();
  }

  Widget _buildCategoryBarChart(List<Map<String, dynamic>> values) {
    final data = _normalizedCategoryData(values);
    if (data.isEmpty) {
      return _emptyCard('No category chart data available.');
    }

    final maxY = data
        .map((item) => item['count'] as double)
        .reduce(max)
        .clamp(1, double.infinity);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Volume (Bar Chart)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 210,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY / 4).toDouble(),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                minY: 0,
                maxY: maxY * 1.2,
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Color(0xFFA0AEC0),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final label = (data[index]['label'] as String);
                        final short = label.length > 8
                            ? '${label.substring(0, 8)}…'
                            : label;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            short,
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(data.length, (index) {
                  final count = data[index]['count'] as double;
                  final color = _chartPalette[index % _chartPalette.length];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: count,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                        color: color,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart(List<Map<String, dynamic>> values) {
    final data = _normalizedCategoryData(values);
    if (data.isEmpty) {
      return _emptyCard('No category share data available.');
    }

    final total = data.fold<double>(
      0,
      (sum, item) => sum + (item['count'] as double),
    );

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Share (Pie Chart)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 30,
                      sectionsSpace: 2,
                      sections: List.generate(data.length, (index) {
                        final count = data[index]['count'] as double;
                        final pct = total == 0 ? 0 : (count / total * 100);
                        final color =
                            _chartPalette[index % _chartPalette.length];
                        return PieChartSectionData(
                          value: count,
                          color: color,
                          radius: 52,
                          title: '${pct.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (_, index) {
                      final label = data[index]['label'] as String;
                      final count = data[index]['count'] as double;
                      final pct = total == 0 ? 0 : (count / total * 100);
                      final color = _chartPalette[index % _chartPalette.length];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$label (${pct.toStringAsFixed(1)}%)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPieChart(List<Map<String, dynamic>> values) {
    final data = values
        .map((item) {
          final label = _safeText(
            item['status'] ?? item['category'] ?? 'Other',
          );
          final rawCount = item['count'];
          final count = rawCount is num
              ? rawCount.toDouble()
              : double.tryParse('$rawCount') ?? 0;
          return {
            'label': label,
            'count': count,
          };
        })
        .where((item) => (item['count'] as double) > 0)
        .toList();

    if (data.isEmpty) {
      return _emptyCard('No status data available.');
    }

    final total = data.fold<double>(
      0,
      (sum, item) => sum + (item['count'] as double),
    );

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Distribution (Pie Chart)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 30,
                      sectionsSpace: 2,
                      sections: List.generate(data.length, (index) {
                        final count = data[index]['count'] as double;
                        final pct = total == 0 ? 0 : (count / total * 100);
                        final color =
                            _chartPalette[index % _chartPalette.length];
                        return PieChartSectionData(
                          value: count,
                          color: color,
                          radius: 52,
                          title: '${pct.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (_, index) {
                      final label = data[index]['label'] as String;
                      final count = data[index]['count'] as double;
                      final pct = total == 0 ? 0 : (count / total * 100);
                      final color = _chartPalette[index % _chartPalette.length];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$label (${pct.toStringAsFixed(1)}%)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    final insights = _asMapList(_insightsData['insights']);
    final hotspots = _asMapList(_insightsData['hotspots']);
    final trending = _asMapList(_insightsData['trending']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pattern Detection and Insights',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        if (insights.isEmpty)
          _emptyCard('No significant trends detected yet.')
        else
          ...insights.map((insight) {
            final severity = _safeText(insight['severity'], fallback: 'medium');
            final severityColor = severity == 'high'
                ? const Color(0xFFEF4444)
                : severity == 'low'
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: severityColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _safeText(insight['message']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Current: ${_safeText(insight['current'])}  •  Previous: ${_safeText(insight['previous'])}  •  Change: ${_safeText(insight['change_pct'])}%',
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 6),
        const Text(
          'Problem Hotspots',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        if (hotspots.isEmpty)
          _emptyCard('No hotspots data available.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hotspots
                .map(
                  (hotspot) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '${_safeText(hotspot['location'])} (${_safeText(hotspot['count'])})',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 12),
        const Text(
          'Trending Complaints',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        if (trending.isEmpty)
          _emptyCard('No trending complaints yet.')
        else
          ...trending.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _safeText(item['category']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _safeText(item['description']),
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Location: ${_safeText(item['location'])}',
                          style: const TextStyle(
                            color: Color(0xFFA0AEC0),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '👍 ${_safeText(item['upvotes'])}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPredictionsSection() {
    final predictions = _asMapList(_predictionsData['predictions']);
    final seasonalAlerts = _asMapList(_predictionsData['seasonal_alerts']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Future Issue Predictions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        if (predictions.isEmpty)
          _emptyCard('Not enough data for predictions yet.')
        else
          ...predictions.map((prediction) {
            final risk =
                _safeText(prediction['risk_level'], fallback: 'medium');
            final riskColor = risk == 'high'
                ? const Color(0xFFEF4444)
                : risk == 'low'
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: riskColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _safeText(prediction['category']).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _safeText(prediction['message']),
                    style: const TextStyle(color: Color(0xFFE2E8F0)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Average: ${_safeText(prediction['avg_weekly'])}/week  •  Next week: ${_safeText(prediction['predicted_next_week'])}  •  Risk: $risk',
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 8),
        const Text(
          'Seasonal Alerts',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        if (seasonalAlerts.isEmpty)
          _emptyCard('No seasonal alerts right now.')
        else
          ...seasonalAlerts.map(
            (alert) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.5)),
              ),
              child: Text(
                _safeText(alert['message']),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMapSection() {
    final markers = _complaints.map((complaint) {
      final point = _resolveComplaintPosition(complaint);
      final priority = _safeText(complaint['priority'], fallback: 'medium');
      final color = _priorityColor(priority);

      return Marker(
        point: point,
        width: 26,
        height: 26,
        child: Tooltip(
          message:
              '${_safeText(complaint['id'])}\n${_safeText(complaint['category'])}\n${_safeText(complaint['status'])}',
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Complaint Map View',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              _legendItem('High', const Color(0xFFEF4444)),
              const SizedBox(width: 12),
              _legendItem('Medium', const Color(0xFFF59E0B)),
              const SizedBox(width: 12),
              _legendItem('Low', const Color(0xFF10B981)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 420,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(22.9734, 78.6569),
              initialZoom: 4.6,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'civic_grievance_system',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Plotted complaints: ${_complaints.length}',
          style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
        ),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFE2E8F0)),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_activeSection) {
      case 'predictions':
        return _buildPredictionsSection();
      case 'map':
        return _buildMapSection();
      default:
        return _buildInsightsSection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final byCategory = _asMapList(_summary['by_category']);
    final byStatus = _asMapList(_summary['by_status']);

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
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFEF4444), size: 42),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadAnalyticsData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Admin Analytics',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Insights, predictions and map intelligence',
                                    style: TextStyle(
                                      color: Color(0xFFA0AEC0),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _loadAnalyticsData,
                                    icon: const Icon(Icons.refresh,
                                        color: Colors.white),
                                  ),
                                  IconButton(
                                    onPressed: () => context.pop(),
                                    icon: const Icon(Icons.arrow_back,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 102,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _statCard(
                                  'Total',
                                  _safeText(_summary['total'], fallback: '0'),
                                  'Total registered complaints',
                                  const Color(0xFF6366F1),
                                ),
                                _statCard(
                                  'Pending',
                                  _safeText(_summary['pending'], fallback: '0'),
                                  'Awaiting active action',
                                  const Color(0xFFF59E0B),
                                ),
                                _statCard(
                                  'Resolved',
                                  _safeText(_summary['resolved'],
                                      fallback: '0'),
                                  '${_safeText(_summary['resolution_rate'], fallback: '0')}% resolution rate',
                                  const Color(0xFF10B981),
                                ),
                                _statCard(
                                  'High Priority',
                                  _safeText(_summary['high_priority'],
                                      fallback: '0'),
                                  'Critical complaint count',
                                  const Color(0xFFEF4444),
                                ),
                              ],
                            ),
                          ),
                          _buildCategoryBarChart(byCategory),
                          _buildCategoryPieChart(byCategory),
                          _distributionCard(
                            'Category Distribution',
                            byCategory,
                            const Color(0xFF667EEA),
                          ),
                          _buildStatusPieChart(byStatus),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _sectionChip('insights', 'Insights'),
                              _sectionChip('predictions', 'Predictions'),
                              _sectionChip('map', 'Map'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSectionContent(),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
