import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_weekly_planner/screens/auth/login_screen.dart';

void main() {
  testWidgets('login form shows validation errors for empty fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Please enter your email.'), findsOneWidget);
    expect(find.text('Please enter your password.'), findsOneWidget);
  });

  testWidgets('login form rejects invalid email', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'bad-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Please enter a valid email address.'), findsOneWidget);
  });
}
