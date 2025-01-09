import 'package:flutter/material.dart';
import 'package:my_project/screens/admin_dashboard_screen.dart';
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
        '/dashboard': (context) => DashboardScreen(),  // Definición de ruta
        '/admin-dashboard': (context) => AdminDashboardScreen(),
      },
    );
  }
}
