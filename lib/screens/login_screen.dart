import 'package:flutter/material.dart';
import 'package:my_project/services/auth_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

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

    final success = await _authService.login(signInEmail, accessCredentials, context);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Get first login flag
      final loginFirst = _authService.loginFirst;

      // Redirect to update password if it's the first login
      if (loginFirst == true) {
        Navigator.pushReplacementNamed(context, '/update-password');
        return;
      }

      // Access the token from AuthService
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

      // Redirect based on the user's role
      if (permission == "main" || permission == "top") {
        Navigator.pushReplacementNamed(context, '/main-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/home-dashboard');
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
        title: Text("Instituto de Estadísticas de Puerto Rico"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 152, 230, 88),
      ),
      backgroundColor: const Color.fromARGB(255, 0, 51, 102),
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
                  SizedBox(height: 20),
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
