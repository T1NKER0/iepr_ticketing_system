import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboardScreen extends StatelessWidget {
  // Función para verificar si el usuario está autenticado
  Future<bool> _isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  // Función para cerrar sesión
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Elimina el token

    // Redirigir a la pantalla de login
    Navigator.pushReplacementNamed(context, '/');
  }

  // Función para redirigir al administrador a otras secciones
  void _goToTickets(BuildContext context) {
    Navigator.pushNamed(context, '/admin-tickets'); // Reemplazar con ruta de Tickets
  }

  void _goToUsers(BuildContext context) {
    Navigator.pushNamed(context, '/admin-users'); // Reemplazar con ruta de Usuarios
  }

  void _goToRoles(BuildContext context) {
    Navigator.pushNamed(context, '/admin-roles'); // Reemplazar con ruta de Roles
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAuthenticated(),
      builder: (context, snapshot) {
        // Mostrar un indicador de carga mientras verificamos el estado de la sesión
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si no está autenticado, redirigimos al login
        if (!snapshot.data!) {
          Future.microtask(() => Navigator.pushReplacementNamed(context, '/'));
          return SizedBox.shrink(); // Widget vacío mientras redirige
        }

        // Si está autenticado, mostramos el contenido del Dashboard
        return Scaffold(
          appBar: AppBar(
            title: Text("IEPR IT Ticketing System - Admin Dashboard"),
            centerTitle: true,
            backgroundColor: Colors.green.shade700,
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
                      "Welcome, Admin!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _goToTickets(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text("Manage Tickets", style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _goToUsers(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text("Manage Users", style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _goToRoles(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text("Manage Roles", style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(height: 20),
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
