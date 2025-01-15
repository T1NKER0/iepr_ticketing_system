import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateTicketScreen extends StatefulWidget {
  @override
  _CreateTicketScreenState createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Función para verificar si el usuario está autenticado y su rol
  Future<bool> _isAuthorized() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenExists = prefs.containsKey('token');
    final role = prefs.getString('role');
    return tokenExists && role != '1'; // Asegura que el rol NO sea "1" (admin)
  }

  // Simular guardar el ticket
  Future<void> _submitTicket() async {
    if (_formKey.currentState!.validate()) {
      final ticketData = {
        "title": _titleController.text,
        "description": _descriptionController.text,
      };

      // Aquí harías la lógica para enviar el ticket a tu backend
      print("Ticket creado: $ticketData");

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Ticket creado con éxito!'),
          duration: Duration(seconds: 2), // Tiempo de visualización del mensaje
        ),
      );

      // Limpiar el formulario
      _titleController.clear();
      _descriptionController.clear();

      // Esperar que el mensaje se muestre antes de redirigir
      await Future.delayed(Duration(seconds: 2));

      // Redirigir a home-dashboard
      Navigator.pushReplacementNamed(context, '/home-dashboard');
    }
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

        // Si no está autorizado (es admin o no está autenticado), redirigimos al login o al dashboard
        if (!snapshot.hasData || !snapshot.data!) {
          Future.microtask(() => Navigator.pushReplacementNamed(context, '/home-dashboard'));
          return SizedBox.shrink(); // Widget vacío mientras redirige
        }

        // Si está autorizado, mostramos el contenido de la página
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "Crear Ticket",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green.shade700,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: "Título",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El título es requerido';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: "Descripción",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La descripción es requerida';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 114, 41, 108), // Purple color
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        "Crear Ticket",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 16),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/home-dashboard');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 114, 41, 108), // Purple color
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          "Volver",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
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
