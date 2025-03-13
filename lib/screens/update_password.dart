import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_project/services/auth_service.dart';

class UpdatePassword extends StatefulWidget {
  @override
  _UpdatePasswordState createState() => _UpdatePasswordState();
}

class _UpdatePasswordState extends State<UpdatePassword> {
  String? userEmail;
  bool isLoading = true;
  bool isError = false;
  String errorMessage = '';
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');

    if (email == null) {
      setState(() {
        isError = true;
        errorMessage = 'No se pudo obtener el usuario autenticado';
      });
    } else {
      setState(() {
        userEmail = email;
        isLoading = false;
      });
    }
  }

  Future<void> _logoutAndRedirect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Elimina todos los datos almacenados

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/'); // Redirige al login
    }
  }

  Future<void> resetPassword() async {
    if (passwordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
      _showMessageDialog('Error', 'Los campos no pueden estar vacíos');
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showMessageDialog('Error', 'Las contraseñas no coinciden');
      return;
    }

    final authService = AuthService();
    await authService.loadFromPreferences();
    final token = authService.token;

    if (token == null) {
      _showMessageDialog('Error', 'Usuario no autenticado');
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/update-password/$userEmail'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'newCredentials': passwordController.text}),
      );

      if (response.statusCode == 200) {
        _showMessageDialog('Éxito', 'Contraseña actualizada correctamente');
        passwordController.clear();
        confirmPasswordController.clear();
      } else {
        final data = json.decode(response.body);
        _showMessageDialog('Error', data['message']);
      }
    } catch (e) {
      _showMessageDialog('Error', 'Error al actualizar la contraseña: $e');
    }
  }

  void _showMessageDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cambiar Contraseña'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back), // Icono de retroceso
          onPressed: _logoutAndRedirect, // Llamada a la función de cierre de sesión
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : isError
                ? Center(child: Text(errorMessage))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Usuario: $userEmail', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 20),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: 'Ingrese nueva contraseña'),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: 'Confirme nueva contraseña'),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: resetPassword,
                        child: Text('Actualizar Contraseña'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
