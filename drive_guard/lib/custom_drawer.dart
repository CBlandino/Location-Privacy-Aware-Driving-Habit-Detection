import 'package:flutter/material.dart';
import 'login_page.dart';
import 'current_trip_page.dart'; // Import StartTripPage
import 'previous_trips_page.dart'; // Import PreviousTripsPage
import 'score_page.dart'; // Import ScorePage
import 'settings_page.dart'; // Import SettingsPage

class CustomDrawer extends StatelessWidget {
  final String role;

  CustomDrawer({required this.role});

  @override
  Widget build(BuildContext context) {
    String accountName = '';
    String accountEmail = '';

    if (role == 'User') {
      accountName = 'John Doe';
      accountEmail = 'john.doe@example.com';
    } else if (role == 'Insurance Provider') {
      accountName = 'Insurance Co.';
      accountEmail = 'provider@example.com';
    } else if (role == 'Service Provider') {
      accountName = 'Server #1234';
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
          if (role == 'User') ...[
            ListTile(
              leading: Icon(Icons.play_arrow),
              title: Text('Start Trip'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CurrentTripPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Previous Trips'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PreviousTripsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.star),
              title: Text('Your Score'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScorePage()),
                );
              },
            ),
          ] else if (role == 'Insurance Provider') ...[
            ListTile(
              leading: Icon(Icons.person_search),
              title: Text('User Lookup'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.directions_car),
              title: Text('User Trips'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.score),
              title: Text('User Score'),
              onTap: () {},
            ),
          ] else if (role == 'Service Provider') ...[
            ListTile(
              leading: Icon(Icons.create),
              title: Text('ID Generator'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('Server Information'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.person_search),
              title: Text('User Lookup'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.business),
              title: Text('Insurance Lookup'),
              onTap: () {},
            ),
          ],
          Spacer(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                    SettingsPage()
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
                MaterialPageRoute(builder: (context) => LoginPageWidget()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
