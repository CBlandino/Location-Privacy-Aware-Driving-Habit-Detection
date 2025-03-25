import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'current_trip_page.dart';
import 'previous_trips_page.dart';
import 'score_page.dart';
import 'settings_page.dart';

class CustomDrawer extends StatefulWidget {
  final String role;

  CustomDrawer({required this.role});

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String accountName = 'Loading...';
  String accountEmail = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? userName = prefs.getString('user_name');
    String? userEmail = prefs.getString('user_email');

    setState(() {
      accountName = userName ?? 'Unknown User';
      accountEmail = userEmail ?? 'No Email';
    });
  }

  // Logout Function - Clears token and redirects to login page
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); // Remove authentication token
    await prefs.remove('user_name');
    await prefs.remove('user_email');

    // Navigate to login page and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPageWidget()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          if (widget.role == 'User') ...[
            _buildDrawerItem(Icons.play_arrow, 'Start Trip', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CurrentTripPage()));
            }),
            _buildDrawerItem(Icons.history, 'Previous Trips', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PreviousTripsPage()));
            }),
            _buildDrawerItem(Icons.star, 'Your Score', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ScorePage()));
            }),
          ] else if (widget.role == 'Insurance Provider') ...[
            _buildDrawerItem(Icons.person_search, 'User Lookup', () {}),
            _buildDrawerItem(Icons.directions_car, 'User Trips', () {}),
            _buildDrawerItem(Icons.score, 'User Score', () {}),
          ] else if (widget.role == 'Service Provider') ...[
            _buildDrawerItem(Icons.create, 'ID Generator', () {}),
            _buildDrawerItem(Icons.info, 'Server Information', () {}),
            _buildDrawerItem(Icons.person_search, 'User Lookup', () {}),
            _buildDrawerItem(Icons.business, 'Insurance Lookup', () {}),
          ],
          Spacer(),
          _buildDrawerItem(Icons.settings, 'Settings', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
          }),
          _buildDrawerItem(Icons.exit_to_app, 'Logout', () => _logout(context)),
        ],
      ),
    );
  }

  // Helper method to create drawer items
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
