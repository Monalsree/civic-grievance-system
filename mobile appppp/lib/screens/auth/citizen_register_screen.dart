import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../widgets/voice_input_button.dart';

class CitizenRegisterScreen extends StatefulWidget {
  const CitizenRegisterScreen({super.key});

  @override
  State<CitizenRegisterScreen> createState() => _CitizenRegisterScreenState();
}

class _CitizenRegisterScreenState extends State<CitizenRegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^\d{10}$')
        .hasMatch(phone.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  Future<void> _register() async {
    // Validation
    if (_nameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill all fields');
      return;
    }

    if (_nameController.text.length < 2) {
      setState(() => _errorMessage = 'Name must be at least 2 characters');
      return;
    }

    if (_usernameController.text.length < 3) {
      setState(() => _errorMessage = 'Username must be at least 3 characters');
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    if (!_isValidPhone(_phoneController.text)) {
      setState(
          () => _errorMessage = 'Please enter a valid 10-digit phone number');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    if (_passwordController.text.length < 4) {
      setState(() => _errorMessage = 'Password must be at least 4 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.register(
        username: _usernameController.text,
        email: _emailController.text,
        name: _nameController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        role: 'citizen',
      );

      if (response['success'] && mounted) {
        // Show confirmation dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: const Color(0xFF111827),
            title: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF43e97b),
                    Color(0xFF38f9d7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: Text(
                  '✅ Registration Successful!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Icon(Icons.check_circle,
                    color: Color(0xFF43e97b), size: 64),
                const SizedBox(height: 16),
                Text(
                  'Welcome, ${_nameController.text}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your account has been successfully created. You can now login with your credentials.',
                  style: TextStyle(
                    color: Color(0xFFa0aec0),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
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
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/login-citizen');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Login Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        setState(
            () => _errorMessage = response['message'] ?? 'Registration failed');
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
                  const SizedBox(height: 20),
                  // Header
                  const Text(
                    'Register as Citizen',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your account to submit complaints',
                    style: TextStyle(
                      color: Color(0xFFa0aec0),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
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
                  // Full Name
                  _buildInputField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 12),
                  // Username
                  _buildInputField(
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.account_circle,
                  ),
                  const SizedBox(height: 12),
                  // Email
                  _buildInputField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  // Phone
                  _buildInputField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  // Password
                  _buildPasswordField(
                    controller: _passwordController,
                    label: 'Password',
                    showPassword: _showPassword,
                    onToggle: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                  const SizedBox(height: 12),
                  // Confirm Password
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    showPassword: _showConfirmPassword,
                    onToggle: () => setState(
                        () => _showConfirmPassword = !_showConfirmPassword),
                  ),
                  const SizedBox(height: 24),
                  // Register button
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
                        onTap: _isLoading ? null : _register,
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
                                    'Create Account',
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
                  const SizedBox(height: 16),
                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: Color(0xFFa0aec0),
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login-citizen'),
                        child: const Text(
                          'Login',
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
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
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFF718096)),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
          suffixIcon: VoiceInputButton(
            controller: controller,
            idleColor: const Color(0xFF667eea),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool showPassword,
    required VoidCallback onToggle,
  }) {
    return Container(
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
        controller: controller,
        obscureText: !showPassword,
        style: const TextStyle(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFF718096)),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.lock, color: Color(0xFF667eea)),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              showPassword ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFF667eea),
            ),
          ),
        ),
      ),
    );
  }
}
