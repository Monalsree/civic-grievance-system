import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  final bool isAuthenticated;
  final Widget Function(BuildContext) builder;
  final Widget Function(BuildContext)? unauthenticatedBuilder;

  const AuthWrapper({
    super.key,
    required this.isAuthenticated,
    required this.builder,
    this.unauthenticatedBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (isAuthenticated) {
      return builder(context);
    } else if (unauthenticatedBuilder != null) {
      return unauthenticatedBuilder!(context);
    } else {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
  }
}
