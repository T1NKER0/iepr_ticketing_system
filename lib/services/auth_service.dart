import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/material.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  String? _token;
  String? _permission;
  String? _unique;
  bool? _loginFirst; // New variable to store the first login flag
  String? _email; // New variable to store the email

  String? get token => _token;
  String? get permission => _permission;
  String? get unique => _unique;
  bool? get loginFirst => _loginFirst; // Getter for first login flag
  String? get email => _email; // Getter for the email

  final String _baseUrl = 'http://localhost:3000'; 

  Future<bool> login(String email, String password, context) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'signInEmail': email, 'accessCredentials': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('permission') && data['permission'] != null) {
          _permission = data['permission'];

          if (data.containsKey('token') && data['token'] != null) {
            _token = data['token'];

            // Save token, role, unique field, and email to SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', _token!);
            await prefs.setString('permission', _permission!);
            await prefs.setString('email', email); // Save email

            if (data['access'] != null) {
              if (data['access']['unique'] != null) {
                _unique = data['access']['unique'];
                await prefs.setString('unique', _unique!);
              }

              if (data['access']['loginFirst'] != null) {
                _loginFirst = data['access']['loginFirst'];
                await prefs.setBool('loginFirst', _loginFirst!);
              }
            }

            print('Login successful: ${data['access']}, Permission: ${data['permission']}');

            // Redirect if first login
            if (_loginFirst == true) {
              Navigator.pushReplacementNamed(context, '/update-password');
            }

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
    _unique = prefs.getString('unique');
    _loginFirst = prefs.getBool('loginFirst'); // Load loginFirst from storage
    _email = prefs.getString('email'); // Load email from storage
  }
}
