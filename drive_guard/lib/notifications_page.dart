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
          title: 'Notifications',
          children: <Widget>[
            SettingsGroup(
              title: 'Notification Preferences',
              children: [
                SwitchSettingsTile(
                  settingKey: 'trip_summary_notifications',
                  title: 'Trip Summaries',
                  subtitle: 'Receive a summary after each trip',
                  leading: Icon(Icons.directions_car),
                  defaultValue: true,
                  onChange: (value) {
                    // Handle toggle logic if needed
                  },
                ),
                SwitchSettingsTile(
                  settingKey: 'driving_score_notifications',
                  title: 'Driving Score Updates',
                  subtitle: 'Get notified when your score changes',
                  leading: Icon(Icons.bar_chart),
                  defaultValue: true,
                ),
                SwitchSettingsTile(
                  settingKey: 'reminder_notifications',
                  title: 'Driving Reminders',
                  subtitle: 'Get occasional safe driving tips and reminders',
                  leading: Icon(Icons.alarm),
                  defaultValue: false,
                ),
              ],
            ),
          ],
        ),
      );
}