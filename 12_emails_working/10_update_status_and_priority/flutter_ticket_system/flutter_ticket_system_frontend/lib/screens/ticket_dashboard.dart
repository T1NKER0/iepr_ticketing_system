import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TicketDashboardScreen extends StatelessWidget {
  Future<bool> _isAuthorized() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenExists = prefs.containsKey('token');
    final permission = prefs.getString('permission');
    return tokenExists && (permission == 'main' || permission == 'top');
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

        if (!snapshot.data!) {
          Future.microtask(() => Navigator.pushReplacementNamed(context, '/'));
          return SizedBox.shrink();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text("Ticket Dashboard"),
            centerTitle: true,
            backgroundColor: Colors.green,
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
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/manage-tickets'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      child: Text("Ver Todos los Tickets", style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/my-tickets'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      child: Text("Ver Mis Tickets", style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/main-dashboard'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      child: Text("Volver", style: TextStyle(color: Colors.white)),
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
