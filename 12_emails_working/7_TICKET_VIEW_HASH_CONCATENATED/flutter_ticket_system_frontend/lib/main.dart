import 'package:flutter/material.dart';
import 'package:my_project/screens/admin_dashboard_screen.dart';
import 'package:my_project/screens/create_ticket_screen.dart';
import 'package:my_project/screens/create_user_screen.dart';
import 'package:my_project/screens/manage_users_screen.dart';
import 'package:my_project/screens/view_tickets_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:my_project/utils/constants.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login',
      theme: ThemeData(
        primaryColor: kPrimaryColor, // Se usa kPrimaryColor para el color principal
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/home-dashboard': (context) => DashboardScreen(),  // Definición de ruta
        '/admin-dashboard': (context) => AdminDashboardScreen(), //ruta para administracion
        '/request-dashboard': (context) => CreateTicketScreen(), //ruta general
        '/manage-users': (context) => ManageUsersScreen(),
        '/add-users': (context) => CreateUserScreen(),
        '/manage-tickets': (context) => ViewTicketsScreen(),
      },
    );
  }
}
