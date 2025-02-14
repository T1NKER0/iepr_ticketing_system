import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_project/services/auth_service.dart'; // Assuming AuthService is defined in this file

class DeleteUserScreen extends StatefulWidget {
  @override
  _DeleteUserScreenState createState() => _DeleteUserScreenState();
}

class _DeleteUserScreenState extends State<DeleteUserScreen> {
  List<String> users = []; // List to hold the user names
  String? selectedUser;
  bool isLoading = true;
  bool isError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  // Fetch all users from the backend
  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/targets'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          users = List<String>.from(data['targets'].map((user) => user['username']));
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
          errorMessage = 'Failed to load users';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = 'Error fetching users: $e';
      });
    }
  }

  // Delete the selected user
  Future<void> deleteUser(String username) async {
    if (username.isEmpty) return;

    // Retrieve the token from AuthService
    final authService = AuthService();
    await authService.loadFromPreferences(); // Load token from SharedPreferences
    final token = authService.token;

    if (token == null) {
      // Handle case where token is not available
      print("Token is missing, user is not authenticated");
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/delete-user/$username'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          users.remove(username); // Remove the deleted user from the list
          selectedUser = null; // Deselect the user
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Success'),
            content: Text('User deleted successfully'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        final data = json.decode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text(data['message']),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Error deleting user: $e'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Delete User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : isError
                ? Center(child: Text(errorMessage))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DropdownButton<String>(
                        value: selectedUser,
                        hint: Text('Select User to Delete'),
                        isExpanded: true,
                        items: users.map((user) {
                          return DropdownMenuItem<String>(
                            value: user,
                            child: Text(user),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedUser = newValue;
                          });
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: selectedUser == null
                            ? null
                            : () {
                                deleteUser(selectedUser!);
                              },
                        child: Text('Delete User'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
