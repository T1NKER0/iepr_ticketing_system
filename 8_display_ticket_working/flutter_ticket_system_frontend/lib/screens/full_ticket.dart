import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class FullTicketScreen extends StatefulWidget {
  @override
  _FullTicketScreenState createState() => _FullTicketScreenState();
}

class _FullTicketScreenState extends State<FullTicketScreen> {
  int? id; // Nullable to avoid issues
  bool _isLoading = true;
  Map<String, dynamic> _ticketDetails = {};
  String? _userRole; // Store user role

  // Verifies if the user is authorized
  Future<bool> _isAuthorized() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenExists = prefs.containsKey('token');
    final permission = prefs.getString('permission');

    if (permission != 'main' && permission != 'top') {
      await prefs.clear();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
      return false;
    }

    _userRole = permission; // Save the user role
    return tokenExists;
  }

  // Fetches the ticket details from the API
  Future<void> _fetchTicketDetails() async {
    if (id == null) {
      setState(() => _isLoading = false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/ticket/$id'), // Use $id to pass the correct ticket ID
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _ticketDetails = data['ticket'] ?? {};
        });
      } else {
        throw Exception('Error fetching ticket');
      }
    } catch (e) {
      print('API Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener los detalles del ticket.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Asigna el ticket al usuario
  Future<void> _assignTicket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('http://localhost:3000/assign-ticket'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'ticketId': id}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket asignado correctamente.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al asignar el ticket.')),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if arguments are passed correctly
    final args = ModalRoute.of(context)?.settings.arguments;
    print("Ticket ID recibido: $args");

    if (args != null && args is int) {
      id = args;
      _fetchTicketDetails();
    } else {
      print("No ticket ID received, returning.");
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
          return SizedBox.shrink();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text("Detalles del Ticket", style: TextStyle(color: Colors.white)),
            backgroundColor: const Color.fromARGB(255, 152, 230, 88),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_ticketDetails.isNotEmpty) ...[
                          Text("Asunto: ${_ticketDetails['title'] ?? 'N/A'}", style: TextStyle(fontSize: 20)),
                          SizedBox(height: 10),
                          Text("Descripción: ${_ticketDetails['description'] ?? 'N/A'}", style: TextStyle(fontSize: 16)),
                          SizedBox(height: 10),
                          Text("Origen: ${_ticketDetails['username'] ?? 'N/A'}", style: TextStyle(fontSize: 16)),
                          SizedBox(height: 10),
                          Text("Urgencia: ${_ticketDetails['priority'] ?? 'N/A'}", style: TextStyle(fontSize: 16)),
                          SizedBox(height: 10),
                          Text("Estado: ${_ticketDetails['status'] ?? 'N/A'}", style: TextStyle(fontSize: 16)),
                          SizedBox(height: 20),
                          // Show button only if role is 'top'
                          if (_userRole == 'top')
                            ElevatedButton(
                              onPressed: _assignTicket,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                "Asignar Ticket",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                        ] else
                          Text("No se encontraron detalles para este ticket."),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
