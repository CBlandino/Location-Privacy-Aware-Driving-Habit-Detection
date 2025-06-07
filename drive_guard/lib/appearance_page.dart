import 'package:drive_guard/login_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';





class AppearancePage extends StatefulWidget {
  @override
  _AppearancePageState createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  
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
        leading: Icon(Icons.remove_red_eye_outlined, color: Colors.black),
        title: 'Appearance',
        child: SettingsScreen(
          children: <Widget>[
            // build functionality here
          ],
        ),
      );
}