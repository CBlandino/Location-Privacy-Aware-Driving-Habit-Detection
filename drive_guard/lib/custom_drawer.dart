import 'package:flutter/material.dart';
import 'login_page.dart'; // Ensure LoginPage is imported

class CustomDrawer extends StatelessWidget {
  final String role;

  CustomDrawer({required this.role});

  @override
  Widget build(BuildContext context) {
    String accountName = '';
    String accountEmail = '';

    if (role == 'User') {
      accountName = 'John Doe'; // Name for the User
      accountEmail = 'john.doe@example.com';
    } else if (role == 'Insurance Provider') {
      accountName = 'Insurance Co.'; // Provider Name
      accountEmail = 'provider@example.com';
    } else if (role == 'Service Provider') {
      accountName = 'Server #1234'; // Server number as the first name
      accountEmail = 'service.provider@example.com';
    }

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(accountName),
            accountEmail: Text(accountEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
            decoration: BoxDecoration(color: Colors.blue.shade700),
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Profile'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Logout'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPageWidget()),
                (route) => false, // Remove all previous routes
              );
            },
          ),
        ],
      ),
    );
  }
}
