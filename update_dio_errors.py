import os
import glob
import re

auth_dir = r"d:\civic-grievance-system\mobile appppp\lib\screens\auth"
api_path = r"d:\civic-grievance-system\mobile appppp\lib\services\api_service.dart"

# 1. Update API Service to properly handle Dio exceptions and extract the real error message
with open(api_path, 'r', encoding='utf-8') as f:
    api_content = f.read()

# Make sure dio is imported fully
if "import 'package:dio/dio.dart';" not in api_content:
    api_content = "import 'package:dio/dio.dart';\n" + api_content
    
# Replace the raw try/catch blocks that just throw `Exception(e)` to ones that extract DioException messages
# A safe way is to create a dynamic exception handler helper at the end of the file.

helper = """
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
"""

if "_handleError" not in api_content:
    # replace the final closing brace of the class with the helper
    api_content = api_content[:api_content.rfind('}')] + helper

# Now rewrite throw Exception(...) to throw Exception(_handleError(e)) in login and register
api_content = re.sub(r"throw Exception\('Login failed: \$e'\);", r"throw Exception(_handleError(e));", api_content)
api_content = re.sub(r"throw Exception\('Registration failed: \$e'\);", r"throw Exception(_handleError(e));", api_content)

with open(api_path, 'w', encoding='utf-8') as f:
    f.write(api_content)


# 2. Update Auth screens to cleanly format the Exception string (remove 'Exception: ' prefix)
files = glob.glob(os.path.join(auth_dir, "*.dart"))

for file_path in files:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    old_catch = "setState(() => _errorMessage = 'Error: ${e.toString()}');"
    # We replace it with logic that strips "Exception: " if it exists, so it just says "Username already exists" instead of "Error: Exception: Username already exists"
    new_catch = r"setState(() { String msg = e.toString(); if (msg.startsWith('Exception: ')) msg = msg.substring(11); _errorMessage = msg; });"
    
    # Another variant
    old_catch2 = "setState(() => _errorMessage = e.toString());"
    
    if old_catch in content or old_catch2 in content:
        content = content.replace(old_catch, new_catch)
        content = content.replace(old_catch2, new_catch)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)

print("DioExceptions replaced with clean user-facing error messages!")
