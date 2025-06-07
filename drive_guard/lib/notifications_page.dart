import 'package:drive_guard/login_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';





class NotificationsPage extends StatefulWidget {
  // Keys for SharedPreferences storage

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  
  @override
  void initState() {
    super.initState();
    // Verify user is authenticated
    _checkAuthToken();
  }

  // Checks if the user has a valid authentication token.
  // If not, redirects to the login page.
  Future<void> _checkAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPageWidget()),
      );
    }
  }
  
  
   @override
  Widget build(BuildContext context) => SimpleSettingsTile(
        leading: Icon(Icons.notifications_none_rounded, color: Colors.black),
        title: 'Notifications',
        child: SettingsScreen(
          children: <Widget>[
          ],
        ),
      );
}