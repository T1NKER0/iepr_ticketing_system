import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  String? _token;
  String? _role;

  String? get token => _token;
  String? get role => _role;

  final String _baseUrl = 'http://localhost:3000'; // Asegúrate de que la URL esté correcta

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Verificar que los campos necesarios estén presentes
        if (data.containsKey('role') && data['role'] != null) {
          _role = data['role'];

          // Si el token está presente en la respuesta, guárdalo
          if (data.containsKey('token') && data['token'] != null) {
            _token = data['token'];

            // Guarda en SharedPreferences si es necesario
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', _token!);
            await prefs.setString('role', _role!);

            print('Login exitoso: ${data['user']}, Rol: ${data['role']}');
            return true;
          } else {
            print('Falta el token en la respuesta del servidor');
            return false;
          }
        } else {
          print("Faltan campos en la respuesta: role");
          return false;
        }
      } else {
        final error = jsonDecode(response.body)['message'];
        print('Error en login: $error');
        return false;
      }
    } catch (e) {
      print('Error en la solicitud: $e');
      return false;
    }
  }

  Future<void> loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _role = prefs.getString('role');
  }
}
