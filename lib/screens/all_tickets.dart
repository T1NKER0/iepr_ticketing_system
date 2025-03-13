import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'full_ticket.dart';

class ViewTicketsScreen extends StatefulWidget {
  @override
  _ViewTicketsScreenState createState() => _ViewTicketsScreenState();
}

class _ViewTicketsScreenState extends State<ViewTicketsScreen> {
  bool _isLoading = true;
  List<dynamic> _tickets = [];

  // Check if the user is authorized
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

  // Fetch tickets from the API
  Future<void> _fetchTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://localhost:3000/requests'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
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

  // Assign ticket function
  Future<void> _assignTicket(int ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('http://localhost:3000/assign-ticket'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'ticketId': ticketId}),
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
                        return Card(
                          margin: EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(ticket['subject']),
                            subtitle: Text(ticket['urgent']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _assignTicket(ticket['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                  child: Text("Asignar Ticket", style: TextStyle(color: Colors.white)),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FullTicketScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: Text("Ver Ticket", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/admin-dashboard');
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
