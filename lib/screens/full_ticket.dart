import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FullTicketScreen extends StatefulWidget {
  @override
  _FullTicketScreenState createState() => _FullTicketScreenState();
}

class _FullTicketScreenState extends State<FullTicketScreen> {
  int? id; // Nullable to avoid issues
  bool _isLoading = true;
  Map<String, dynamic> _ticketDetails = {};
  String? _userRole; // Store user role
  List<Map<String, dynamic>> _admins = []; // Store list of admin data (id, name)
  String? _selectedUser; // Store selected admin name
  String? _selectedUserId; // Store selected admin ID
  String? _selectedUrgency; // Store selected urgency value

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
        Uri.parse('http://localhost:3000/request/$id'), // Use $id to pass the correct ticket ID
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _ticketDetails = data['request'] ?? {};
          print("Ticket ID for this ticket:  $id");
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

  // Fetches the admins from the API
  Future<void> _fetchAdmins() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/admins'), // Correct endpoint to get admins
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Admin Response: ${response.body}');  // Log the response body

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if the 'admins' key exists and is a valid list
        if (data != null && data['admins'] != null) {
          final admins = data['admins'] as List;
          setState(() {
            _admins = admins.map((admin) {
              return {
                'id': admin['email'],  // Correctly map to 'user_id'
                'name': admin['name'],    // Correctly map to 'name'
              };
            }).toList();
          });
        } else {
          print('Error: "admins" key not found or is not a List');
          setState(() {
            _admins = [];
          });
        }
      } else {
        throw Exception('Error fetching admins');
      }
    } catch (e) {
      print('API Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener los admins.')),
      );
      setState(() {
        _admins = [];
      });
    }
  }

  // Assign the ticket to the selected admin
  Future<void> _assignTicket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, seleccione un admin para asignar.')),
      );
      return;
    }

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ID de ticket no válido.')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://localhost:3000/assign-request'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'requestId': id, // Pass the ticket ID
        'authId': _selectedUserId, // Pass the admin ID
      }),
    );

    print('Assign Response: ${response.body}');  // Log the response body

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

  // Update ticket urgency
  Future<void> _updateUrgency(String urgency) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ID de ticket no válido.')),
      );
      return;
    }

    // Log the ticket ID and urgency for debugging
    print("Sending request to update priority for ticket ID: $id with urgency: $urgency");

    final response = await http.put(
      Uri.parse('http://localhost:3000/update-request-urgent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'requestId': id,  // Ensure the correct ticket ID is being passed
        'urgent': urgency, // Pass the selected urgency
      }),
    );

    print('Urgency Update Response: ${response.body}');  // Log the response body

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prioridad del ticket actualizada a $urgency.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la prioridad del ticket.')),
      );
    }
  }

  // Close the ticket
  Future<void> _closeTicket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ID de ticket no válido.')),
      );
      return;
    }

    final response = await http.put(
      Uri.parse('http://localhost:3000/update-request-state'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'requestId': id, 
        'state': 'Cerrado'  
      }),
    );

    print('Close Ticket Response: ${response.body}');  // Log the response body

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket cerrado correctamente.')),
      );
      // Update the ticket status to "Cerrado" immediately
      setState(() {
        _ticketDetails['status'] = 'Cerrado';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar el ticket.')),
      );
    }
  }
  
  // Method to generate PDF from ticket details
  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Instituto de Estadisticas de Puerto Rico  \nDepartamento de Sistemas de Informacion',  ),
              pw.Text('\nAsunto: ${_ticketDetails['title'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 10),
              pw.Text('Descripción: ${_ticketDetails['description'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text('Origen: ${_ticketDetails['username'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text('Urgencia: ${_ticketDetails['priority'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text('Estado: ${_ticketDetails['status'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 16)),
              pw.Text('\nFirma del Solicitante: ____________________'),
              pw.Text('\nFirma del Gerente de Sistemas de Informacion: ____________________'),
              pw.Text('\nFirma del Tecnico: ____________________'),
            ],
          );
        },
      ),
    );

    // Use the printing package to provide options to both share and save the PDF
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get ticket ID passed as argument
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is int) {
      id = args;
      _fetchTicketDetails();
      _fetchAdmins(); // Fetch admins when ticket details are loaded
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

                          // Button to download the ticket information as a PDF
                          ElevatedButton(
                            onPressed: _generatePdf,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              "Descargar Información del Ticket como PDF",
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                          
                          // Dropdown for admin selection
                          if (_userRole == 'top' && _admins.isNotEmpty)
                            DropdownButton<String>(
                              value: _selectedUser ?? (_admins.isNotEmpty ? _admins.first['name'] : null),
                              hint: Text("Seleccione un admin"),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedUser = newValue;
                                  final selectedAdmin = _admins.firstWhere(
                                    (admin) => admin['name'] == newValue,
                                    orElse: () => {'id': null, 'name': null}, // Cambio aquí: en vez de '', ahora es null
                                  );
                                  _selectedUserId = selectedAdmin['id']; // Ahora será null si no se encuentra
                                });
                              },
                              items: _admins.map((admin) {
                                return DropdownMenuItem<String>(
                                  value: admin['name'],
                                  child: Text(admin['name']),
                                );
                              }).toList(),
                            ),

                          // Button to assign the ticket
                          if (_userRole == 'top') ...[
                            SizedBox(height: 20),
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
                            SizedBox(height: 20),

                            // Urgency List and Button
                            Text("Actualizar Urgencia", style: TextStyle(fontSize: 18)),
                            DropdownButton<String>(
                              value: _selectedUrgency,
                              hint: Text("Seleccione urgencia"),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedUrgency = newValue;
                                });
                              },
                              items: ['Baja', 'Media', 'Alta'].map((String urgency) {
                                return DropdownMenuItem<String>(
                                  value: urgency,
                                  child: Text(urgency),
                                );
                              }).toList(),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (_selectedUrgency != null) {
                                  _updateUrgency(_selectedUrgency!);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Por favor, seleccione una urgencia.')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                "Actualizar Prioridad",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                            SizedBox(height: 20),

                            // Close Ticket Button
                            ElevatedButton(
                              onPressed: _closeTicket,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                "Cerrar Ticket",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ]
                        ],
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}