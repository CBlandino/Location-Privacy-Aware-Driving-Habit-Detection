import 'package:drive_guard/login_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';





class AboutPage extends StatefulWidget {
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  
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
    leading: Icon(Icons.question_mark_rounded, color: Colors.black),
    title: 'About',
    child: SettingsScreen(
      title: 'About',
      children: <Widget>[
        SettingsGroup(
          title: 'About NoTrackDrive',
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'NoTrackDrive is a privacy-focused mobile app that empowers drivers to benefit from insurance-based driving metrics without compromising their location privacy.\n\n'
                'Unlike traditional telematics apps that continuously track your routes, NoTrackDrive uses a proprietary method to locally process driving behavior — ensuring that sensitive GPS data never leaves your device.\n\n'
                'The app promotes safer driving habits while giving users control over their personal data, making it a secure and user-first solution for usage-based insurance.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 20),
            // Thank you box with app version
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    'App Version 1.0.0',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Thank you for using NoTrackDrive!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}