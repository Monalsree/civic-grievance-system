import 'package:shared_preferences/shared_preferences.dart';
import '../models/complaint_model.dart';
import 'dart:convert';

class ComplaintService {
  static const String _complaintsCacheKey = 'complaints_cache';

  late SharedPreferences _prefs;
  List<Complaint> _cachedComplaints = [];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromCache();
  }

  void _loadFromCache() {
    final cached = _prefs.getString(_complaintsCacheKey);
    if (cached != null) {
      final List<dynamic> decoded = jsonDecode(cached);
      _cachedComplaints = decoded
          .map((c) => Complaint.fromJson(c as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> cacheComplaints(List<Complaint> complaints) async {
    _cachedComplaints = complaints;
    final encoded = jsonEncode(complaints.map((c) => c.toJson()).toList());
    await _prefs.setString(_complaintsCacheKey, encoded);
  }

  List<Complaint> getCachedComplaints() => _cachedComplaints;

  Future<void> addToCache(Complaint complaint) async {
    _cachedComplaints.add(complaint);
    final encoded =
        jsonEncode(_cachedComplaints.map((c) => c.toJson()).toList());
    await _prefs.setString(_complaintsCacheKey, encoded);
  }

  void clear() {
    _cachedComplaints = [];
    _prefs.remove(_complaintsCacheKey);
  }
}
