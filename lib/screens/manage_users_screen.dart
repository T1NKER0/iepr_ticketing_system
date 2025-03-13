import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageUsersScreen extends StatefulWidget {
  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  // Verificar el rol del usuario
  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final permission = prefs.getString('permission');

    // Si el rol no es "1", cerrar sesión y redirigir al login
    if (permission != 'main' && permission != 'top') {
      await prefs.clear(); // Limpiar los datos de sesión
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkUserRole(); // Verificar el rol al iniciar la pantalla
  }

  // Función para regresar al Admin Dashboard
  void _goBack(BuildContext context) {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/main-dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gestionar Usuarios"),
        backgroundColor: const Color.fromARGB(255, 152, 230, 88),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/add-users'); // Redirige a la pantalla de creación de usuario
              },
              child: Text("Agregar Usuario"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Trigger user modification (can be customized later)
                // Navigate to modify user screen
                 Navigator.pushNamed(context, '/reset-password'); 
              },
              child: Text("Modificar Usuario"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Redirect to /delete-users route without additional logic
                Navigator.pushNamed(context, '/delete-users');
              },
              child: Text("Eliminar Usuario"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _goBack(context),
              child: Text("Volver"),
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
