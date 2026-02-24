//auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://127.0.0.1:8000/api/";

  Future<Map<String, dynamic>> signup(
    String username,
    String email,
    String password,
  ) async {
    final url = Uri.parse('${baseUrl}signup/');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return {'success': true, 'message': 'Account created successfully!'};
    } else {
      return {'success': false, 'message': 'Signup failed. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('${baseUrl}login/');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'message': 'Login successful!',
        'token':
            data['access'], // JWT Token (you may use it for further requests)
      };
    } else {
      return {'success': false, 'message': 'Invalid credentials.'};
    }
  }
}
