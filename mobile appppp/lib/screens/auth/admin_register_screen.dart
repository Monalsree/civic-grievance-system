import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../widgets/voice_input_button.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _setupKeyController = TextEditingController();
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _designationController = TextEditingController();
  final _createdByController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _officeZoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();

  static const List<String> _roleLevels = [
    'super_admin',
    'department_admin',
    'staff_officer',
  ];

  String _selectedRoleLevel = 'department_admin';

  bool _showSetupKey = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _setupKeyController.dispose();
    _nameController.dispose();
    _employeeIdController.dispose();
    _designationController.dispose();
    _createdByController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _officeZoneController.dispose();
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

  bool _isProfessionalEmail(String email) {
    if (!_isValidEmail(email)) return false;
    final domain = email.split('@').last.toLowerCase().trim();
    const blocked = {'gmail.com', 'yahoo.com', 'outlook.com', 'hotmail.com'};
    return !blocked.contains(domain);
  }

  Future<void> _register() async {
    if (_setupKeyController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _employeeIdController.text.trim().isEmpty ||
        _designationController.text.trim().isEmpty ||
        _departmentController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() =>
          _errorMessage = 'Please fill all mandatory professional fields');
      return;
    }

    if (_nameController.text.trim().length < 2) {
      setState(() => _errorMessage = 'Name must be at least 2 characters');
      return;
    }

    if (_usernameController.text.trim().length < 3) {
      setState(() => _errorMessage = 'Username must be at least 3 characters');
      return;
    }

    if (!_isProfessionalEmail(_emailController.text.trim())) {
      setState(() => _errorMessage =
          'Use an official organization email (personal domains are not allowed)');
      return;
    }

    if (!_isValidPhone(_phoneController.text.trim())) {
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
      final response = await _apiService.createAdminAccount(
        setupKey: _setupKeyController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        employeeId: _employeeIdController.text.trim(),
        department: _departmentController.text.trim(),
        designation: _designationController.text.trim(),
        roleLevel: _selectedRoleLevel,
        officeZone: _officeZoneController.text.trim(),
        createdByAdmin: _createdByController.text.trim(),
      );

      if (response['success'] && mounted) {
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
                  'Professional admin account created successfully. You can now login and manage the system by your assigned role.',
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
                      context.go('/login-admin');
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
        setState(() =>
            _errorMessage = response['message'] ?? 'Admin onboarding failed');
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
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.black, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Admin Professional Onboarding',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use official staff identity details and setup key',
                    style: TextStyle(color: Color(0xFFa0aec0), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFfee2e2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFef4444), width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Color(0xFFef4444), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFF991b1b),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildPasswordField(
                    controller: _setupKeyController,
                    label: 'Admin Setup Key *',
                    showPassword: _showSetupKey,
                    onToggle: () =>
                        setState(() => _showSetupKey = !_showSetupKey),
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _nameController,
                    label: 'Official Full Name *',
                    icon: Icons.badge,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _employeeIdController,
                    label: 'Employee ID / Staff Number *',
                    icon: Icons.numbers,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _designationController,
                    label: 'Designation *',
                    icon: Icons.work,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _departmentController,
                    label: 'Department *',
                    icon: Icons.apartment,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _officeZoneController,
                    label: 'Office Zone (Optional)',
                    icon: Icons.location_city,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRoleLevel,
                        isExpanded: true,
                        items: _roleLevels
                            .map(
                              (level) => DropdownMenuItem<String>(
                                value: level,
                                child: Text(
                                    level.replaceAll('_', ' ').toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedRoleLevel = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _usernameController,
                    label: 'Admin Username *',
                    icon: Icons.account_circle,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _emailController,
                    label: 'Official Email *',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _phoneController,
                    label: 'Official Phone Number *',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _createdByController,
                    label: 'Created By (Super Admin Username)',
                    icon: Icons.person_pin,
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordField(
                    controller: _passwordController,
                    label: 'Password *',
                    showPassword: _showPassword,
                    onToggle: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password *',
                    showPassword: _showConfirmPassword,
                    onToggle: () => setState(
                        () => _showConfirmPassword = !_showConfirmPassword),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
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
                                          Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Create Professional Admin',
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
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an admin account? ',
                        style:
                            TextStyle(color: Color(0xFFa0aec0), fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login-admin'),
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
