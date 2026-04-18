import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../widgets/voice_input_button.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _apiService = ApiService();

  bool _showPassword = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );

      if (response['user'] != null &&
          (response['token'] != null || response['access_token'] != null)) {
        final tokenStr = response['token'] ?? response['access_token'];
        final user = User.fromJson(response['user']);
        if (user.role != 'admin') {
          setState(() {
            _errorMessage =
                'This account is not an admin account. Please use citizen login.';
          });
          return;
        }

        await _authService.saveUser(user, tokenStr);
        if (mounted) {
          context.go('/admin-dashboard');
        }
      } else {
        setState(() => _errorMessage = response['message'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() {
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) msg = msg.substring(11);
        _errorMessage = msg;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0e27),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0a0e27),
              const Color(0xFF1a1f3a),
            ],
          ),
        ),
        constraints: BoxConstraints.expand(),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Header
                  const Text(
                    'Admin Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage complaints and system settings',
                    style: TextStyle(
                      color: Color(0xFFa0aec0),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Error message
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(
                            0xFFfee2e2), // Very light red background

                        borderRadius: BorderRadius.circular(12),

                        border: Border.all(
                          color: const Color(0xFFef4444), // Strong red border

                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Color(0xFFef4444), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFF991b1b), // Dark red text

                                fontSize: 14,

                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Username field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Username',
                        hintStyle: const TextStyle(color: Color(0xFF718096)),
                        border: InputBorder.none,
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Color(0xFF667eea),
                        ),
                        suffixIcon: VoiceInputButton(
                          controller: _usernameController,
                          idleColor: Color(0xFF667eea),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Password field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Color(0xFF718096)),
                        border: InputBorder.none,
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Color(0xFF667eea),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () =>
                              setState(() => _showPassword = !_showPassword),
                          child: Icon(
                            _showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFF667eea),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Login button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF667eea),
                          Color(0xFF764ba2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withValues(alpha: 76),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _login,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Need admin onboarding? ',
                        style: TextStyle(
                          color: Color(0xFFa0aec0),
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/register-admin'),
                        child: const Text(
                          'Create with setup key',
                          style: TextStyle(
                            color: Color(0xFF667eea),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
