import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Column(
          children: [
            // Decorative header
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.withValues(alpha: 0.25),
                    Colors.blue.withValues(alpha: 0.12),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text(
                          '🏛️',
                          style: TextStyle(fontSize: 34),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Civic Grievance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Your Voice, Our Priority',
                      style: TextStyle(
                        color: Color(0xFFa0aec0),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Role selection buttons
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Select Your Role',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Choose how you want to access the system',
                        style: TextStyle(
                          color: Color(0xFFa0aec0),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // Citizen Button
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedRole = 'citizen');
                          Future.delayed(const Duration(milliseconds: 300), () {
                            context.push('/login-citizen');
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: _selectedRole == 'citizen'
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF667eea),
                                      Color(0xFF764ba2),
                                    ],
                                  )
                                : const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFE2E8F0),
                                      Color(0xFFCBD5E1),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedRole == 'citizen'
                                  ? Colors.transparent
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _selectedRole == 'citizen'
                                    ? const Color(0xFF667eea)
                                        .withValues(alpha: 0.4)
                                    : Colors.black.withValues(alpha: 0.1),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 24,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'citizen'
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 32,
                                  color: _selectedRole == 'citizen'
                                      ? Colors.white
                                      : const Color(0xFF4A5568),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Citizen',
                                      style: TextStyle(
                                        color: _selectedRole == 'citizen'
                                            ? Colors.white
                                            : const Color(0xFF1A202C),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Submit and track complaints',
                                      style: TextStyle(
                                        color: _selectedRole == 'citizen'
                                            ? Colors.white
                                                .withValues(alpha: 0.8)
                                            : const Color(0xFF4A5568),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Admin Button
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedRole = 'admin');
                          Future.delayed(const Duration(milliseconds: 300), () {
                            context.push('/login-admin');
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: _selectedRole == 'admin'
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF667eea),
                                      Color(0xFF764ba2),
                                    ],
                                  )
                                : const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFE2E8F0),
                                      Color(0xFFCBD5E1),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedRole == 'admin'
                                  ? Colors.transparent
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _selectedRole == 'admin'
                                    ? const Color(0xFF667eea)
                                        .withValues(alpha: 0.4)
                                    : Colors.black.withValues(alpha: 0.1),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 24,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'admin'
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.admin_panel_settings,
                                  size: 32,
                                  color: _selectedRole == 'admin'
                                      ? Colors.white
                                      : const Color(0xFF4A5568),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Administrator',
                                      style: TextStyle(
                                        color: _selectedRole == 'admin'
                                            ? Colors.white
                                            : const Color(0xFF1A202C),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Manage complaints and system',
                                      style: TextStyle(
                                        color: _selectedRole == 'admin'
                                            ? Colors.white
                                                .withValues(alpha: 0.8)
                                            : const Color(0xFF4A5568),
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
