import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  String? _token;
  String? _permission;
  int? _unique; // Variable to store the unique field

  String? get token => _token;
  String? get permission => _permission;
  int? get unique => _unique; // Getter for the unique field

  final String _baseUrl = 'http://localhost:3000'; // Update with your actual API URL

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'signInEmail': email, 'accessCredentials': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if response contains necessary fields
        if (data.containsKey('permission') && data['permission'] != null) {
          _permission = data['permission'];

          if (data.containsKey('token') && data['token'] != null) {
            _token = data['token'];

            // Save token, role, and unique field to SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', _token!);
            await prefs.setString('permission', _permission!);

            if (data['access'] != null && data['access']['unique'] != null) {
              _unique = data['access']['unique']; // Save the unique field
              await prefs.setInt('unique', _unique!);
            }

            print('Login successful: ${data['access']}, Permission: ${data['permission']}');
            return true;
          } else {
            print('Token is missing from the server response');
            return false;
          }
        } else {
          print("Response is missing required fields: permission");
          return false;
        }
      } else {
        final error = jsonDecode(response.body)['message'];
        print('Login error: $error');
        return false;
      }
    } catch (e) {
      print('Request error: $e');
      return false;
    }
  }

  Future<void> loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _permission = prefs.getString('permission');
    _unique = prefs.getInt('unique'); // Load the unique field from preferences
  }
}
