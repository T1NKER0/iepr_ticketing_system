import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String _baseUrl = 'http://localhost:3000'; 

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Login exitoso: ${data['user']}');
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']); // Guarda el token
          return true;
        } else {
          print("Error: Token no presente en la respuesta.");
          return false;
        }
      } else {
        print('Error en login: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error en la solicitud: $e');
      return false;
    }
  }
}
