import 'package:drive_guard/login_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';





class HelpSupportPage extends StatefulWidget {
  @override
  _HelpSupportPageState createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  
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
    leading: Icon(Icons.headphones_outlined, color: Colors.black),
    title: 'Help & Support',
    child: SettingsScreen(
      title: 'Help & Support',
      children: <Widget>[
        SettingsGroup(
          title: 'Support Options',
          children: [
            SimpleSettingsTile(
              title: 'FAQs',
              subtitle: 'Browse frequently asked questions',
              leading: Icon(Icons.question_answer),
              onTap: () {
                // TODO: Navigate to FAQs screen or open a web page
              },
            ),
            SimpleSettingsTile(
              title: 'Contact Support',
              subtitle: 'Get help from our team',
              leading: Icon(Icons.support_agent),
              onTap: () {
                // TODO: Navigate to a contact form or open email intent
              },
            ),
          ],
        ),
        SettingsGroup(
          title: 'Feedback',
          children: [
            SimpleSettingsTile(
              title: 'Report a Bug',
              subtitle: 'Let us know about issues you’re facing',
              leading: Icon(Icons.bug_report),
              onTap: () {
                // TODO: Navigate to bug report form
              },
            ),
            SimpleSettingsTile(
              title: 'Send Feedback',
              subtitle: 'Help us improve your experience',
              leading: Icon(Icons.feedback),
              onTap: () {
                // TODO: Navigate to feedback form
              },
            ),
          ],
        ),
      ],
    ),
  );
}