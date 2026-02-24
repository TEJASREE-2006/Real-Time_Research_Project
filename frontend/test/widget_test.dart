import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/signup_page.dart';
import 'package:flutter_application_1/login_page.dart'; // Adjust if file name is different

void main() {
  testWidgets('Sign Up Page Test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignupPage()));

    // Look for text fields
    expect(find.byType(TextFormField), findsNWidgets(2));

    // Look for the sign-up button using the ElevatedButton and text
    expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
  });

  testWidgets('Login Page Test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    // Ensure 2 input fields are present
    expect(find.byType(TextFormField), findsNWidgets(2));

    // Check for Login button
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}
