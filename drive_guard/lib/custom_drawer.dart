import 'package:flutter/material.dart';
import 'account_settings_page.dart';
import 'login_page.dart';

class CustomDrawer extends StatelessWidget {
  final String role;

  const CustomDrawer({super.key, required this.role});

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
          if (role == 'User') ...[
            ListTile(
              leading: Icon(Icons.directions_car),
              title: Text('Car Models'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Previous Trips'),
              onTap: () {},
            ),
          ],
          // Add a Spacer widget to push the rest to the top
          Spacer(),
          Divider(), // Divider for separation
          // Account Settings and Logout are now at the bottom
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Account Settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountSettingsPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Logout'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                (route) => false, // Remove all previous routes
              );
            },
          ),
        ],
      ),
    );
  }
}
