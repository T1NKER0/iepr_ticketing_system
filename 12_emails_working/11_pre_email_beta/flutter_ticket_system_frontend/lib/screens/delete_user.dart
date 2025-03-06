import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_project/services/auth_service.dart'; // Asegúrate de que este servicio está bien definido

class DeleteUserScreen extends StatefulWidget {
  @override
  _DeleteUserScreenState createState() => _DeleteUserScreenState();
}

class _DeleteUserScreenState extends State<DeleteUserScreen> {
  List<String> users = []; // Lista de usuarios
  String? selectedUser;
  bool isLoading = true;
  bool isError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkUserRole(); // Verifica el rol antes de cargar la pantalla
  }

  // Verifica si el usuario tiene permisos para acceder
  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final permission = prefs.getString('permission');

    if (permission != 'main' && permission != 'top') {
      await prefs.clear(); // Limpia los datos de sesión
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } else {
      fetchUsers(); // Cargar usuarios si tiene permisos correctos
    }
  }

  // Obtiene todos los usuarios del backend
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

  // Elimina el usuario seleccionado
  Future<void> deleteUser(String signIn) async {
    if (signIn.isEmpty) return;

    final authService = AuthService();
    await authService.loadFromPreferences(); // Cargar token almacenado
    final token = authService.token;

    if (token == null) {
      print("Token no disponible, el usuario no está autenticado");
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/delete-user/$signIn'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          users.remove(signIn);
          selectedUser = null;
        });
        _showMessageDialog('Éxito', 'Usuario eliminado correctamente');
      } else {
        final data = json.decode(response.body);
        _showMessageDialog('Error', data['message']);
      }
    } catch (e) {
      _showMessageDialog('Error', 'Error al eliminar usuario: $e');
    }
  }

  // Muestra un cuadro de diálogo con un mensaje
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
      appBar: AppBar(title: Text('Eliminar Usuario')),
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
                        hint: Text('Selecciona un usuario para eliminar'),
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
                      ElevatedButton(
                        onPressed: selectedUser == null
                            ? null
                            : () {
                                deleteUser(selectedUser!);
                              },
                        child: Text('Eliminar Usuario'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
