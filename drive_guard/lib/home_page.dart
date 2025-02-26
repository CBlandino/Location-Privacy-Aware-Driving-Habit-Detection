import 'package:flutter/material.dart';
import 'custom_drawer.dart';

// Home page where users land after logging in.
// Future Enhancements:
// - Add role-based dashboard customization
// - Implement notifications and dynamic content
// - Improve UI with additional widgets
class HomePage extends StatelessWidget {
  final String role; // Role of the logged-in user, used to customize the UI
  const HomePage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('$role Dashboard'),
        backgroundColor: Colors.blue.shade700,
      ),
      drawer: CustomDrawer(role: role), // Custom drawer for navigation
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Welcome, $role! Here you can manage your account.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}