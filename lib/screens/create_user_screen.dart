import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class CreateUserScreen extends StatefulWidget {
  @override
  _CreateUserScreenState createState() => _CreateUserScreenState();
  
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _initialPasswordController = TextEditingController();
  
  int? _selectedPermission;
  List<dynamic> _permissions = [];

  Future<bool> _isAuthorized() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenExists = prefs.containsKey('token');
    final permission = prefs.getString('permission');

     // Si el rol no es "1", cerrar sesión y redirigir al login
    if (permission != 'main' && permission != 'top') {
      await prefs.clear(); // Limpiar los datos de sesión
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }}
    return tokenExists && (permission == 'main' || permission =='top');
  }

  

  // Obtener roles desde la API
  Future<void> _fetchRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    final response = await http.get(
      Uri.parse('http://localhost:3000/permissions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("API Response: $data"); // Debugging

      setState(() {
        _permissions = data['permissions'] ?? [];
        
        

        // Validar que _selectedRole tenga un valor correcto
        if (_permissions.isNotEmpty) {
          final validRoles = _permissions.map((p) => p['permissionId']).toSet();
          if (_selectedPermission == null || !validRoles.contains(_selectedPermission)) {
            _selectedPermission = _permissions.first['permissionId'];
          }
        }
      });
    } else {
      print("Error fetching roles: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener los roles.')),
      );
    }
  }

  Future<void> _submitUser() async {
    if (_formKey.currentState!.validate() && _selectedPermission != null) {
      final userData = {
        "id": _usernameController.text,
        "nameOfUser": _nameController.text,
        "accessEmail": _emailController.text,
        "accessCredentials":  _initialPasswordController.text,
        "permission": _selectedPermission,
      };

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No estás autenticado.')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('http://localhost:3000/add-user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(userData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Usuario creado con éxito!')),
        );
        _usernameController.clear();
        _nameController.clear();
        _emailController.clear();
        _initialPasswordController.clear();

        await Future.delayed(Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/manage-users');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el usuario.')),
        );
      }
    } else if (_selectedPermission == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, seleccione un rol.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchRoles(); // Cargar roles al iniciar
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAuthorized(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!) {
          Future.microtask(() => Navigator.pushReplacementNamed(context, '/home-dashboard'));
          return SizedBox.shrink();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Crear Usuario", style: TextStyle(color: Colors.white)),
            backgroundColor:  const Color.fromARGB(255, 152, 230, 88),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(_usernameController, "Nombre de usuario", false),
                    SizedBox(height: 16),
                    _buildTextField(_nameController, "Nombre completo", false),
                    SizedBox(height: 16),
                    _buildTextField(_emailController, "Correo electrónico", false),
                    SizedBox(height: 16),
                    _buildTextField(_initialPasswordController, "Contraseña Inicial", true),
                    SizedBox(height: 16),
                    _buildRoleDropdown(),
                    SizedBox(height: 16),
                    _buildElevatedButton("Crear Usuario", _submitUser),
                    SizedBox(height: 16),
                    _buildElevatedButton("Volver", () => Navigator.pushReplacementNamed(context, '/manage-users')),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Lista de roles
  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedPermission,
      decoration: InputDecoration(
        labelText: "Seleccionar Rol",
        border: OutlineInputBorder(),
      ),
      onChanged: (int? newValue) {
        setState(() {
          _selectedPermission = newValue;
        });
      },
      items: _permissions.map<DropdownMenuItem<int>>((permission) {
        return DropdownMenuItem<int>(
          value: permission['permissionId'], // Asegurar que el ID sea correcto
          child: Text(permission['permissionName']), // Nombre del rol
        );
      }).toList(),
      validator: (value) {
        if (value == null) {
          return 'El rol es requerido';
        }
        return null;
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool isPassword) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      obscureText: isPassword,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label es requerido';
        }
        if (label == "Correo electrónico" && !value.contains('@')) {
          return 'Ingrese un correo válido';
        }
        return null;
      },
    );
  }

  Widget _buildElevatedButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(255, 114, 41, 108),
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(text, style: TextStyle(fontSize: 16, color: Colors.white)),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _initialPasswordController.dispose();
    super.dispose();
  }
}
