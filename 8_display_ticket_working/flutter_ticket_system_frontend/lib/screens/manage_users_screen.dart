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

  // Función para modificar un usuario
  void _editUser() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController nameController = TextEditingController();
        TextEditingController emailController = TextEditingController();

        

        return AlertDialog(
          title: Text("Modificar Usuario"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Nombre"),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Correo electrónico"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                print("Usuario modificado: ${nameController.text}, ${emailController.text}");
                Navigator.pop(context);
              },
              child: Text("Modificar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
          ],
        );
      },
    );
  }

  // Función para eliminar un usuario
  void _deleteUser() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Eliminar Usuario"),
          content: Text("¿Estás seguro de que quieres eliminar este usuario?"),
          actions: [
            TextButton(
              onPressed: () {
                print("Usuario eliminado");
                Navigator.pop(context);
              },
              child: Text("Eliminar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
          ],
        );
      },
    );
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
        backgroundColor:  const Color.fromARGB(255, 152, 230, 88),
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
              onPressed: _editUser,
              child: Text("Modificar Usuario"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _deleteUser,
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
