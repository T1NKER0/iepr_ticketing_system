import 'package:flutter/material.dart';
import 'package:my_project/screens/admin_dashboard_screen.dart';
import 'package:my_project/screens/create_ticket_screen.dart';
import 'package:my_project/screens/create_user_screen.dart';
import 'package:my_project/screens/manage_users_screen.dart';
import 'package:my_project/screens/view_tickets_screen.dart';
import 'package:my_project/screens/full_ticket.dart'; // Import FullTicketScreen
import 'screens/login_screen.dart';
import 'screens/ticket_dashboard.dart';
import 'screens/dashboard_screen.dart';
import 'package:my_project/screens/delete_user.dart';
import 'package:my_project/screens/reset_password.dart';
import 'package:my_project/screens/update_password.dart';
import 'package:my_project/utils/constants.dart';
import 'screens/my_tickets.dart';

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
        '/home-dashboard': (context) => DashboardScreen(),
        '/main-dashboard': (context) => AdminDashboardScreen(),
        '/request-dashboard': (context) => CreateTicketScreen(),
        '/manage-users': (context) => ManageUsersScreen(),
        '/add-users': (context) => CreateUserScreen(),
        '/manage-tickets': (context) => ViewTicketsScreen(),
        // Define route for FullTicketScreen
        '/full-ticket': (context) => FullTicketScreen(),
        '/delete-users': (context) => DeleteUserScreen(),
        '/ticket-dashboard' : (context) => TicketDashboardScreen(),
        '/my-tickets' : (context) => ViewMyTicketsScreen(),
        '/reset-password': (context) => ResetPassword(),
        '/update-password': (context) => UpdatePassword()

      },
    );
  }
}
