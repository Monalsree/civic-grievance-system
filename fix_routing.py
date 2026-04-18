import os
import glob

files = [
    r"d:\civic-grievance-system\mobile appppp\lib\screens\auth\citizen_login_screen.dart",
    r"d:\civic-grievance-system\mobile appppp\lib\screens\auth\admin_login_screen.dart"
]

for file_path in files:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add missing imports for saving session
    if "import '../../services/auth_service.dart';" not in content:
        content = content.replace("import '../../services/api_service.dart';", 
                                  "import '../../services/auth_service.dart';\nimport '../../services/api_service.dart';\nimport '../../models/user_model.dart';")

    # Hook up the AuthService
    if "_authService =" not in content:
        content = content.replace("final _apiService = ApiService();", 
                                  "final _authService = AuthService();\n  final _apiService = ApiService();")
    
    # ------------------ CITIZEN LOGIC ------------------ 
    if "citizen_login_screen" in file_path:
        old_auth = """      if (response['success']) {
        if (mounted) {
          context.go('/citizen-home');
        }"""
        new_auth = """      if (response['user'] != null && response['token'] != null) {
        await _authService.init();
        await _authService.saveUser(User.fromJson(response['user']), response['token']);
        if (mounted) {
          context.go('/citizen-home');
        }"""
        content = content.replace(old_auth, new_auth)
        
    # ------------------ ADMIN LOGIC ------------------ 
    if "admin_login_screen" in file_path:
        old_auth = """      if (response['success']) {
        if (mounted) {
          context.go('/admin-dashboard');
        }"""
        new_auth = """      if (response['user'] != null && (response['token'] != null || response['access_token'] != null)) {
        await _authService.init();
        final tokenStr = response['token'] ?? response['access_token'];
        await _authService.saveUser(User.fromJson(response['user']), tokenStr);
        if (mounted) {
          context.go('/admin-dashboard');
        }"""
        content = content.replace(old_auth, new_auth)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Auth routing session bug FIXED!")