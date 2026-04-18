class AppConstants {
  // API Configuration
  // Override with: --dart-define=API_BASE_URL=https://your-server-domain
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.234.155.122:5000',
  );
  static const String apiTimeout = '30000'; // 30 seconds

  // Endpoints
  static const String healthEndpoint = '$apiBaseUrl/health';
  static const String loginEndpoint = '$apiBaseUrl/api/auth/login';
  static const String registerEndpoint = '$apiBaseUrl/api/auth/register';
  static const String createComplaintEndpoint = '$apiBaseUrl/api/complaints';
  static const String getComplaintsEndpoint = '$apiBaseUrl/api/complaints';
  static const String getComplaintByIdEndpoint =
      '$apiBaseUrl/api/complaints/{id}';
  static const String updateComplaintEndpoint =
      '$apiBaseUrl/api/complaints/{id}';
  static const String uploadFileEndpoint = '$apiBaseUrl/api/upload';
  static const String getNotificationsEndpoint =
      '$apiBaseUrl/api/notifications';

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String accessTokenKey = 'access_token';

  // App Configuration
  static const String appName = 'Civic Grievance System';
  static const String appVersion = '1.0.0';

  // Complaint Categories
  static const List<String> complaintCategories = [
    'Road & Transportation',
    'Water Supply',
    'Electricity',
    'Sanitation',
    'Public Safety',
    'Health',
    'Education',
    'Corruption',
    'Other'
  ];

  // Complaint Priorities
  static const List<String> complaintPriorities = [
    'Low',
    'Medium',
    'High',
    'Critical'
  ];

  // Complaint Status
  static const List<String> complaintStatus = [
    'Submitted',
    'Under Review',
    'In Progress',
    'Resolved',
    'Closed'
  ];
}
