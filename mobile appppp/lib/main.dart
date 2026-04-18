import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'config/app_theme.dart';
import 'config/constants.dart';
import 'services/index.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/citizen_login_screen.dart';
import 'screens/auth/admin_login_screen.dart';
import 'screens/auth/citizen_register_screen.dart';
import 'screens/auth/admin_register_screen.dart';
import 'screens/citizen/citizen_home_screen.dart';
import 'screens/citizen/submit_complaint_screen.dart';
import 'screens/citizen/my_complaints_screen.dart';
import 'screens/citizen/notifications_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_analytics_screen.dart';

final _authService = AuthService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _authService.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter();
  }

  GoRouter _buildRouter() {
    return GoRouter(
      refreshListenable: _authService,
      initialLocation: _authService.isAuthenticated
          ? (_authService.currentUser?.role == 'admin'
              ? '/admin-dashboard'
              : '/citizen-home')
          : '/role-selection',
      redirect: (context, state) {
        final isAuthenticated = _authService.isAuthenticated;
        final location = state.matchedLocation;

        // Auth routes
        final authRoutes = [
          '/role-selection',
          '/login-citizen',
          '/login-admin',
          '/register-citizen',
          '/register-admin'
        ];
        final isAuthRoute = authRoutes.contains(location);

        if (!isAuthenticated && !isAuthRoute) {
          return '/role-selection';
        }

        if (isAuthenticated && isAuthRoute) {
          return _authService.currentUser?.role == 'admin'
              ? '/admin-dashboard'
              : '/citizen-home';
        }

        return null;
      },
      routes: [
        // Auth routes
        GoRoute(
          path: '/role-selection',
          builder: (context, state) => const RoleSelectionScreen(),
        ),
        GoRoute(
          path: '/login-citizen',
          builder: (context, state) => const CitizenLoginScreen(),
        ),
        GoRoute(
          path: '/login-admin',
          builder: (context, state) => const AdminLoginScreen(),
        ),
        GoRoute(
          path: '/register-citizen',
          builder: (context, state) => const CitizenRegisterScreen(),
        ),
        GoRoute(
          path: '/register-admin',
          builder: (context, state) => const AdminRegisterScreen(),
        ),
        // Citizen routes
        GoRoute(
          path: '/citizen-home',
          builder: (context, state) => const CitizenHomeScreen(),
        ),
        GoRoute(
          path: '/submit-complaint',
          builder: (context, state) => const SubmitComplaintScreen(),
        ),
        GoRoute(
          path: '/my-complaints',
          builder: (context, state) => MyComplaintsScreen(
            initialQuery: state.uri.queryParameters['q'],
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        // Admin routes
        GoRoute(
          path: '/admin-dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin-analytics',
          builder: (context, state) => const AdminAnalyticsScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('Error: ${state.error}'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
