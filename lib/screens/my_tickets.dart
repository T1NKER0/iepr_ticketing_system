import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ViewMyTicketsScreen extends StatefulWidget {
  @override
  _ViewMyTicketsScreenState createState() => _ViewMyTicketsScreenState();
}

class _ViewMyTicketsScreenState extends State<ViewMyTicketsScreen> {
  bool _isLoading = true;
  List<dynamic> _tickets = [];

  // Verifica si el usuario está autorizado
  Future<bool> _isAuthorized() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenExists = prefs.containsKey('token');
    final permission = prefs.getString('permission');

    if (permission != 'main' && permission != 'top') {
      await prefs.clear();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
    return tokenExists && (permission == 'main' || permission == 'top');
  }

  // Obtiene los tickets desde la API
  Future<void> _fetchTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final unique = prefs.getString('unique'); // Get user ID from SharedPreferences
    final email = prefs.getString('email'); // Get email from SharedPreferences

    if (unique == null || email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Usuario no identificado.')),
      );
      return;
    }

    final response = await http.get(
      Uri.parse('http://localhost:3000/my-requests?user_id=$unique&email=$email'), // Pass user ID and email in query
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Tickets fetched: $data");
      setState(() {
        _tickets = data['tickets'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener los tickets.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTickets();
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
            title: Text("Ver Tickets", style: TextStyle(color: Colors.white)),
            backgroundColor: const Color.fromARGB(255, 152, 230, 88),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _tickets.isEmpty
                  ? Center(child: Text("No hay tickets disponibles"))
                  : ListView.builder(
                      itemCount: _tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = _tickets[index];

                        print("Ticket $index: ${ticket['subject']}, Prioridad: ${ticket['urgent']}, Origen: ${ticket['origin']}");

                        return Card(
                          margin: EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(ticket['subject']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Prioridad: ${ticket['urgent']}'),
                                Text('Origen: ${ticket['origin']}'),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/full-ticket',
                                  arguments: ticket['id'],
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              child: Text("Ver Ticket", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        );
                      },
                    ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/ticket-dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 114, 41, 108),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                "Volver al Dashboard",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}
