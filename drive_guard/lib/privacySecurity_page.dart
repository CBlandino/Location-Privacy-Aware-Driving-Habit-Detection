import 'package:drive_guard/changePassword_page.dart';
import 'package:drive_guard/login_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';





class PrivSecPage extends StatefulWidget {
  @override
  _PrivSecPageState createState() => _PrivSecPageState();
}

class _PrivSecPageState extends State<PrivSecPage> {
  
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
    leading: Icon(Icons.lock_outline, color: Colors.black),
    title: 'Privacy & Security',
    child: SettingsScreen(
      title: 'Privacy & Security',
      children: <Widget>[
        SettingsGroup(
          title: 'Security Settings',
          children: [
            SimpleSettingsTile(
              title: 'Change Password',
              subtitle: 'Update your account password',
              leading: Icon(Icons.password),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                );
              },
            ),
            SwitchSettingsTile(
              settingKey: 'biometric_auth',
              title: 'Biometric Login',
              subtitle: 'Use Face or Fingerprint to log in',
              leading: Icon(Icons.fingerprint),
              defaultValue: false,
              onChange: (enabled) {
                // TODO: Enable or disable biometric login
              },
            ),
          ],
        ),
        SettingsGroup(
          title: 'Privacy Options',
          children: [
            SwitchSettingsTile(
              settingKey: 'location_sharing',
              title: 'Location Access',
              subtitle: 'Allow app to access your location',
              leading: Icon(Icons.location_on),
              defaultValue: false,
              onChange: (enabled) {
                // TODO: Handle location permission logic
              },
            ),
            SimpleSettingsTile(
              title: 'Privacy Policy',
              subtitle: 'View how your data is handled',
              leading: Icon(Icons.privacy_tip),
              onTap: () {
                // TODO: Open privacy policy page or URL
              },
            ),
          ],
        ),
      ],
    ),
  );
}