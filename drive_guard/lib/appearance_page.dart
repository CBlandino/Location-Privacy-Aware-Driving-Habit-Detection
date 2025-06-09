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
          title: 'Appearance',
          children: <Widget>[
            SettingsGroup(
              title: 'Display Options',
              children: [
                SwitchSettingsTile(
                  settingKey: 'dark_mode',
                  title: 'Dark Mode',
                  subtitle: 'Reduce eye strain in low light',
                  leading: Icon(Icons.dark_mode),
                  defaultValue: false,
                  onChange: (enabled) {
                    // TODO: Toggle theme mode here if you're using a theme provider
                  },
                ),
                DropDownSettingsTile(
                  settingKey: 'font_size',
                  title: 'Font Size',
                  subtitle: 'Choose a comfortable font size',
                  selected: 1,
                  values: <int, String>{
                    0: 'Small',
                    1: 'Medium',
                    2: 'Large',
                  },
                  onChange: (value) {
                    // TODO: Apply font size change
                  },
                ),
                DropDownSettingsTile(
                  settingKey: 'accent_color',
                  title: 'Accent Color',
                  subtitle: 'Customize the app color',
                  selected: 'Blue',
                  values: <String, String>{
                    'Blue': 'Blue',
                    'Green': 'Green',
                    'Purple': 'Purple',
                    'Red': 'Red',
                  },
                  onChange: (value) {
                    // TODO: Update accent color
                  },
                ),
              ],
            ),
          ],
        ),
      );
}