import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../config/constants.dart';
import '../models/index.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  late Dio _dio;
  String? _token;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  void setToken(String token) {
    _token = token;
  }

  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.data;
    } catch (e) {
      throw Exception('Health check failed: $e');
    }
  }

  // Auth Endpoints
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      if (response.data['token'] != null) {
        setToken(response.data['token']);
      } else if (response.data['access_token'] != null) {
        setToken(response.data['access_token']);
      }
      return response.data;
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String name,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'username': username,
          'email': email,
          'name': name,
          'phone': phone,
          'password': password,
          'role': role,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Map<String, dynamic>> createAdminAccount({
    required String setupKey,
    required String username,
    required String email,
    required String name,
    required String phone,
    required String password,
    required String employeeId,
    required String department,
    required String designation,
    required String roleLevel,
    String officeZone = '',
    String createdByAdmin = '',
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/admin/create',
        data: {
          'setup_key': setupKey,
          'username': username,
          'email': email,
          'name': name,
          'phone': phone,
          'password': password,
          'employee_id': employeeId,
          'department': department,
          'designation': designation,
          'role_level': roleLevel,
          'office_zone': officeZone,
          'created_by_admin': createdByAdmin,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // Complaint Endpoints
  Future<Map<String, dynamic>> createComplaint({
    required String title,
    required String description,
    required String category,
    required String userId,
    String? priority,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? voiceUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/api/complaints',
        data: {
          'title': title,
          'description': description,
          'category': category,
          'user_id': userId,
          'priority': priority,
          'latitude': latitude,
          'longitude': longitude,
          'image_url': imageUrl,
          'voice_url': voiceUrl,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Create complaint failed: $e');
    }
  }

  Future<List<Complaint>> getComplaints({
    String? status,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
        if (category != null) 'category': category,
      };

      final response = await _dio.get(
        '/api/complaints',
        queryParameters: queryParams,
      );

      final data = _extractList(response.data);
      return data
          .whereType<Map>()
          .map((json) => Complaint.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      throw Exception('Get complaints failed: $e');
    }
  }

  Future<Complaint> getComplaintById(String id) async {
    try {
      final response = await _dio.get('/api/complaints/$id');
      final payload = _extractMap(response.data);
      if (payload.isEmpty) {
        throw Exception('Invalid complaint response format');
      }
      return Complaint.fromJson(payload);
    } catch (e) {
      throw Exception('Get complaint failed: $e');
    }
  }

  Future<Map<String, dynamic>> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? resolutionNotes,
  }) async {
    try {
      final response = await _dio.put(
        '/api/complaints/$complaintId/status',
        data: {
          'status': status,
          'notes': resolutionNotes,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Update complaint failed: $e');
    }
  }

  // Citizen complaint submit (supports optional evidence image)
  Future<Map<String, dynamic>> submitCitizenComplaint({
    required String name,
    required String email,
    required String phone,
    required String category,
    required String location,
    required String description,
    required String username,
    double? latitude,
    double? longitude,
    XFile? evidence,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'name': name,
        'email': email,
        'phone': phone,
        'category': category,
        'location': location,
        'description': description,
        'username': username,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      };

      if (evidence != null) {
        final bytes = await evidence.readAsBytes();
        requestData['evidence'] = MultipartFile.fromBytes(
          bytes,
          filename: evidence.name,
        );
      }

      final response = await _dio.post(
        '/api/complaints',
        data: FormData.fromMap(requestData),
        options: Options(contentType: 'multipart/form-data'),
      );

      final payload = _extractMap(response.data);
      if (payload.isEmpty) {
        throw Exception('Invalid complaint submission response format');
      }
      return payload;
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<List<Map<String, dynamic>>> getCitizenComplaints({
    String? phone,
    String? username,
  }) async {
    try {
      final response = await _dio.get(
        '/api/complaints/mine',
        queryParameters: {
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          if (username != null && username.trim().isNotEmpty)
            'username': username.trim(),
        },
      );

      return _extractMapList(response.data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Map<String, dynamic>> searchCitizenComplaints(String query) async {
    try {
      final response = await _dio.get(
        '/api/complaints/search',
        queryParameters: {'q': query},
      );
      final payload = _extractMap(response.data);
      if (payload.isEmpty) {
        throw Exception('Invalid complaint search response format');
      }
      return payload;
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Map<String, dynamic>> getCitizenComplaintDetails(
      String complaintId) async {
    try {
      final response = await _dio.get('/api/complaints/$complaintId');
      final payload = _extractMap(response.data);
      if (payload.isEmpty) {
        throw Exception('Invalid complaint details response format');
      }
      return payload;
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Map<String, dynamic>> upvoteCitizenComplaint({
    required String complaintId,
    required String username,
  }) async {
    try {
      final response = await _dio.post(
        '/api/complaints/$complaintId/upvote',
        data: {'username': username},
      );
      final payload = _extractMap(response.data);
      if (payload.isEmpty) {
        throw Exception('Invalid upvote response format');
      }
      return payload;
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // Admin dashboard and analytics helpers
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final response = await _dio.get('/api/analytics/summary');
      final payload = _extractMap(response.data);
      if (payload.isEmpty) {
        throw Exception('Invalid analytics summary response format');
      }
      return payload;
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Map<String, dynamic>> getAnalyticsInsights() async {
    try {
      final response = await _dio.get('/api/analytics/insights');
      final payload = _extractMap(response.data);
      if (payload.isEmpty) {
        throw Exception('Invalid analytics insights response format');
      }
      return payload;
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Map<String, dynamic>> getAnalyticsPredictions() async {
    try {
      final response = await _dio.get('/api/analytics/predictions');
      final payload = _extractMap(response.data);
      if (payload.isEmpty) {
        throw Exception('Invalid analytics predictions response format');
      }
      return payload;
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<List<Map<String, dynamic>>> getComplaintsRaw() async {
    try {
      final response = await _dio.get('/api/complaints');
      return _extractMapList(response.data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Map<String, dynamic>> getComplaintDetailsRaw(
      String complaintId) async {
    try {
      final response = await _dio.get('/api/complaints/$complaintId');
      final payload = _extractMap(response.data);
      if (payload.isEmpty) {
        throw Exception('Invalid complaint details response format');
      }
      return payload;
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Map<String, dynamic>> updateAdminComplaintStatus({
    required String complaintId,
    required String status,
    String? notes,
  }) async {
    try {
      final response = await _dio.put(
        '/api/complaints/$complaintId/status',
        data: {
          'status': status,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes,
        },
      );
      final payload = _extractMap(response.data);
      if (payload.isEmpty) {
        throw Exception('Invalid status update response format');
      }
      return payload;
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Map<String, dynamic>> upvoteComplaint({
    required String complaintId,
    required String username,
  }) async {
    try {
      final response = await _dio.post(
        '/api/complaints/$complaintId/upvote',
        data: {'username': username},
      );
      final payload = _extractMap(response.data);
      if (payload.isEmpty) {
        throw Exception('Invalid upvote response format');
      }
      return payload;
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // File Upload
  Future<String> uploadFile(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        '/api/upload',
        data: formData,
      );

      return response.data['file_url'] ?? '';
    } catch (e) {
      throw Exception('File upload failed: $e');
    }
  }

  // Get Notifications
  Future<List<UserNotification>> getNotifications() async {
    try {
      final response = await _dio.get('/api/notifications');
      final data = _extractList(response.data);
      return data
          .whereType<Map>()
          .map((json) =>
              UserNotification.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      throw Exception('Get notifications failed: $e');
    }
  }

  dynamic _normalizePayload(dynamic raw) {
    if (raw is String) {
      final text = raw.trim();
      if (text.startsWith('{') || text.startsWith('[')) {
        try {
          return jsonDecode(text);
        } catch (_) {
          return raw;
        }
      }
    }
    return raw;
  }

  List<dynamic> _extractList(dynamic raw) {
    final normalized = _normalizePayload(raw);
    if (normalized is List) {
      return normalized;
    }
    if (normalized is Map && normalized['data'] is List) {
      return normalized['data'] as List<dynamic>;
    }
    return <dynamic>[];
  }

  List<Map<String, dynamic>> _extractMapList(dynamic raw) {
    return _extractList(raw)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> _extractMap(dynamic raw) {
    final normalized = _normalizePayload(raw);
    if (normalized is Map<String, dynamic>) {
      if (normalized['data'] is Map) {
        return Map<String, dynamic>.from(normalized['data'] as Map);
      }
      return normalized;
    }
    if (normalized is Map) {
      if (normalized['data'] is Map) {
        return Map<String, dynamic>.from(normalized['data'] as Map);
      }
      return Map<String, dynamic>.from(normalized);
    }
    return <String, dynamic>{};
  }

  // Helper to extract readable error messages from DioExceptions
  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null && error.response!.data != null) {
        final data = error.response!.data;
        if (data is Map && data.containsKey('message')) {
          return data['message'].toString();
        }
        if (data is Map && data.containsKey('error')) {
          return data['error'].toString();
        }
        return 'Server Error: ${error.response!.statusCode}';
      }
      return 'Network Error: Please check your connection';
    }
    return error.toString();
  }
}
