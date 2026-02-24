// main.dart
import 'package:flutter/material.dart';
import 'login_page.dart'; // Use the actual LoginPage from this file
// Already imported for navigation

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VidGenie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const LoginPage(), // 👈 This uses your actual login_page.dart
    );
  }
}
