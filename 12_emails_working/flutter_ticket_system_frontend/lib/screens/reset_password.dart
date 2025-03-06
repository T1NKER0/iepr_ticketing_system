import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_project/services/auth_service.dart';

class ResetPassword extends StatefulWidget {
  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  List<String> users = [];
  String? selectedUser;
  bool isLoading = true;
  bool isError = false;
  String errorMessage = '';
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final permission = prefs.getString('permission');

    if (permission != 'main' && permission != 'top') {
      await prefs.clear();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } else {
      fetchUsers();
    }
  }

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/targets'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          users = List<String>.from(data['targets'].map((user) => user['email']));
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
          errorMessage = 'No se pudieron cargar los usuarios';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = 'Error al obtener los usuarios: $e';
      });
    }
  }

  Future<void> resetPassword(String email) async {
    if (email.isEmpty) return;
    if (passwordController.text != confirmPasswordController.text) {
      _showMessageDialog('Error', 'Las contraseñas no coinciden');
      return;
    }

    final authService = AuthService();
    await authService.loadFromPreferences();
    final token = authService.token;

    if (token == null) {
      print("Token no disponible, el usuario no está autenticado");
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/reset-password/$email'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'newCredentials': passwordController.text,
          'target': email,
        }),
      );

      if (response.statusCode == 200) {
        _showMessageDialog('Éxito', 'Contraseña reseteada correctamente');
        passwordController.clear();
        confirmPasswordController.clear();
        setState(() {
          selectedUser = null;
        });
      } else {
        final data = json.decode(response.body);
        _showMessageDialog('Error', data['message']);
      }
    } catch (e) {
      _showMessageDialog('Error', 'Error al resetear la contraseña: $e');
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
      appBar: AppBar(title: Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : isError
                ? Center(child: Text(errorMessage))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DropdownButton<String>(
                        value: selectedUser,
                        hint: Text('Selecciona un usuario'),
                        isExpanded: true,
                        items: users.map((user) {
                          return DropdownMenuItem<String>(
                            value: user,
                            child: Text(user),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedUser = newValue;
                          });
                        },
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: 'Ingrese contraseña'),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: 'Confirme contraseña'),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: selectedUser == null
                            ? null
                            : () {
                                resetPassword(selectedUser!);
                              },
                        child: Text('Resetear Contraseña'),
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
