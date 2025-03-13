import 'dart:convert'; // Add this import to handle JSON
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CreateTicketScreen extends StatefulWidget {
  @override
  _CreateTicketScreenState createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Function to verify if the user is authenticated and authorized
  Future<bool> _isAuthorized() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenExists = prefs.containsKey('token');
    final permission = prefs.getString('permission');
    return tokenExists && (permission != 'main' && permission !='top'); // Ensure the role is NOT "1" (admin)
  }

  // Submit the ticket
 Future<void> _submitTicket() async {
  if (_formKey.currentState!.validate()) {
    final prefs = await SharedPreferences.getInstance();

    // Retrieve token and user_id (unique) from SharedPreferences
    final token = prefs.getString('token');
    final uniqueId = prefs.getString('unique'); // Assuming 'unique' represents user_id
    final email = prefs.getString('email'); // Assuming email is saved in SharedPreferences

    if (token == null || uniqueId == null || email == null) {
      // Handle case where token, user_id, or email is missing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No estás autenticado o falta información.')),
      );
      return;
    }

    // Prepare ticket data including user_id
    final ticketData = {
      "subject": _titleController.text,
      "request": _descriptionController.text,
      "uniqueId": uniqueId,
      "email": email,  // Add email to be used in the backend for the email notification
    };

    try {
      // Send the ticket data to the backend
      final response = await http.post(
        Uri.parse('http://localhost:3000/requests'), // Ensure this is the correct backend URL
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(ticketData),
      );

      if (response.statusCode == 200) {
        // Successfully created ticket
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Ticket creado con éxito!')),
        );

        // Clear form fields
        _titleController.clear();
        _descriptionController.clear();

        // Redirect to home dashboard after 2 seconds
        await Future.delayed(Duration(seconds: 2));
        Navigator.pushReplacementNamed(context, '/home-dashboard');
      } else {
        // Handle server-side errors
        final errorMessage = json.decode(response.body)['message'] ?? 'Error al crear el ticket.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      // Handle network or other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de red: $e')),
      );
    }
  }
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
          return SizedBox.shrink(); // Empty widget while redirecting
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "Crear Ticket",
              style: TextStyle(color: Colors.white),
            ),
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
