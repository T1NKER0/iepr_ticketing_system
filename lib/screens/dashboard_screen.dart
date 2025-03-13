import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatelessWidget {
  // Función para verificar si el usuario está autenticado y su rol
  Future<bool> _isAuthorized() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenExists = prefs.containsKey('token');
    final permission = prefs.getString('permission');
    return tokenExists && (permission != 'main' && permission !='top'); // Permitir acceso solo si el rol es "1" (admin)
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Eliminar el token
    await prefs.remove('permission'); // Eliminar el rol

    // Redirigir al login
    Navigator.pushReplacementNamed(context, '/');
  }

  void _createTicket(BuildContext context) {
    Navigator.pushNamed(context, '/request-dashboard');
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

        // Si no está autorizado (el rol no es "1" o no está autenticado), cerramos sesión y redirigimos al login
        if (!snapshot.hasData || !snapshot.data!) {
          Future.microtask(() => _logout(context)); // Cerrar sesión y redirigir
          return SizedBox.shrink(); // Widget vacío mientras redirige
        }

        return Scaffold(
          appBar: AppBar(
            title: Text("Instituto de Estadisticas de Puerto Rico"),
            centerTitle: true,
            backgroundColor:  const Color.fromARGB(255, 152, 230, 88),
            leading: null, // Remove the back button
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () => _logout(context),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade100,
          body: Center(
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
                      "Welcome!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _createTicket(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 110, 23, 151),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text("Create a Ticket", style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text("Logout", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
