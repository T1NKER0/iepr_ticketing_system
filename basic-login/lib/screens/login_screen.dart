import 'package:flutter/material.dart';
import 'package:my_project/services/auth_service.dart';
import 'package:my_project/widgets/custom_button.dart';
import 'package:my_project/widgets/input_field.dart';

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

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Por favor, completa todos los campos")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final success = await _authService.login(email, password);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.pushReplacementNamed(context, '/dashboard');
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
        backgroundColor: Colors.green.shade700,
      ),
      backgroundColor: Colors.green.shade100,
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
                  InputField(
                    controller: _emailController,
                    label: "Correo electrónico",
                    hint: "Ingresa tu correo",
                    obscureText: false,
                  ),
                  SizedBox(height: 20),
                  InputField(
                    controller: _passwordController,
                    label: "Contraseña",
                    hint: "Ingresa tu contraseña",
                    obscureText: true,
                  ),
                  SizedBox(height: 40),
                  _isLoading
                      ? CircularProgressIndicator()
                      : CustomButton(
                          label: "Iniciar sesión",
                          onPressed: _login,
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
