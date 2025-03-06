import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboardScreen extends StatelessWidget {
  // Verificar si el usuario está autenticado y tiene el rol adecuado
  Future<bool> _isAuthorized() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenExists = prefs.containsKey('token');
    final permission = prefs.getString('permission');
    return tokenExists && (permission == 'main' || permission == 'top'); // Asegura que el rol sea "1"
  }

  // Función para cerrar sesión
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Limpia todos los datos de sesión

    // Redirigir a la pantalla de login
    Navigator.pushReplacementNamed(context, '/');
  }

  // Función para redirigir al administrador a otras secciones
  void _goToTickets(BuildContext context) {
    Navigator.pushNamed(context, '/ticket-dashboard'); // Reemplazar con ruta de Tickets
  }

  void _goToUsers(BuildContext context) {
    Navigator.pushNamed(context, '/manage-users'); // Redirige a la página de gestión de usuarios
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAuthorized(),
      builder: (context, snapshot) {
        // Mostrar un indicador de carga mientras verificamos el estado de la sesión y el rol
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si no está autorizado, redirigir al login
        if (!snapshot.data!) {
          Future.microtask(() => _logout(context));
          return SizedBox.shrink(); // Widget vacío mientras redirige
        }

        // Si está autorizado, mostrar el contenido del Dashboard
        return Scaffold(
          appBar: AppBar(
            title: Text("Admin Dashboard"),
            centerTitle: true,
            backgroundColor:  const Color.fromARGB(255, 152, 230, 88),
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
                      onPressed: () => _goToUsers(context), // Redirige a ManageUsersScreen
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text("Manage Users", style: TextStyle(color: Colors.white)),
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
