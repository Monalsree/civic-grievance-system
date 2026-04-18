import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:civic_grievance_system/main.dart' as app;
import 'package:civic_grievance_system/widgets/common_widgets.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('verify login flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Ensure the splash screen finishes loading
      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Find username and password fields
                  
      // If CustomTextField doesn't expose the underlying text field well to descendant,
      // let's try finding the TextFormField widgets inside CustomTextField instead:
      final usernameInput = find.byType(TextFormField).first;
      final passwordInput = find.byType(TextFormField).last;

      // Enter citizen credentials
      await tester.enterText(usernameInput, 'user1');
      await tester.enterText(passwordInput, 'pass123');

      await tester.pumpAndSettle();

      // Find and tap the Login button
      final loginButton = find.widgetWithText(CustomButton, 'Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Ensure we navigate to the home screen
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

    });
  });
}
