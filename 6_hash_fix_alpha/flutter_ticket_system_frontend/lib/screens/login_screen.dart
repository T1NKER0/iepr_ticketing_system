import 'package:flutter/material.dart';
import 'package:my_project/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _authService = AuthService();

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    final signInEmail = _emailController.text.trim();
    final accessCredentials = _passwordController.text.trim();

    if (signInEmail.isEmpty || accessCredentials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Por favor, completa todos los campos")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }


    final success = await _authService.login(signInEmail, accessCredentials);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Accede al token desde el servicio centralizado
      final token = _authService.token;

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al obtener token")),
        );
        return;
      }

      // Decode the JWT to check the role
      final decodedToken = JwtDecoder.decode(token);
      final permission = decodedToken['permission'];

      // Redirige según el rol
      if (permission == "1") {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else if (permission != "1") {
        Navigator.pushReplacementNamed(context, '/home-dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Rol no reconocido")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Credenciales incorrectas")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("IEPR"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 82, 233, 90),
      ),
      backgroundColor: const Color.fromARGB(255, 125, 32, 165),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 8,
            margin: EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "IT Ticketing System",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: "Correo electrónico"),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: "Contraseña"),
                    obscureText: true,
                  ),
                  SizedBox(height: 40),
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _login,
                          child: Text("Iniciar sesión"),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}