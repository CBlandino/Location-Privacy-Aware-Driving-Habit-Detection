import 'dart:io';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'account_page.dart';
import 'package:geolocator/geolocator.dart';







// CURRENTLY UNUSED













class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  _PrivacyPageState createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _isLocationEnabled = Settings.getValue<bool>('key-location-access', defaultValue: false) ?? false;
  String _locationDisplay = "Location: (off)";

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _isLocationEnabled = (Settings.getValue<bool>('key-location-access', defaultValue: false) ?? false) && serviceEnabled;
    });
  }

  Future<void> _handleLocationPermission(bool value) async {
    if (value) {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLocationEnabled = false);
        return;
      } else if (permission == LocationPermission.deniedForever) {
        setState(() => _isLocationEnabled = false);
        _showLocationSettingsDialog();
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLocationEnabled = false);
        _showLocationSettingsDialog();
        return;
      }

      await Settings.setValue('key-location-access', true);
      setState(() => _isLocationEnabled = true);
    } else {
      await Settings.setValue('key-location-access', false);
      setState(() {
        _isLocationEnabled = false;
        _locationDisplay = "Location: (off)";
      });
    }
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Enable Location Services"),
        content: Text("Location access is disabled. Please enable it in settings."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await Geolocator.openAppSettings();
              Navigator.of(context).pop();
            },
            child: Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  Future<void> _getLocation() async {
    if (!_isLocationEnabled) {
      setState(() {
        _locationDisplay = "Location: (off)";
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _locationDisplay = "Location: ${position.latitude}, ${position.longitude}";
      });
    } catch (e) {
      setState(() {
        _locationDisplay = "Failed to get location";
      });
      print("Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleSettingsTile(
      leading: Icon(Icons.privacy_tip, color: Colors.red),
      title: 'Privacy',
      subtitle: 'Location, Security',
      child: SettingsScreen(
        title: 'Privacy Settings',
        children: <Widget>[
          SwitchSettingsTile(
            settingKey: 'key-location-access',
            title: 'Allow Location Access',
            subtitle: 'Enable access to your location',
            leading: Icon(Icons.location_on, color: Colors.blue),
            onChange: (value) => _handleLocationPermission(value),
          ),
          SimpleSettingsTile(
            title: 'Test Location Access',
            subtitle: _locationDisplay,
            leading: Icon(Icons.my_location, color: Colors.purple),
            onTap: _getLocation,
          ),
          SwitchSettingsTile(
            settingKey: 'key-notifications',
            title: 'Allow App Notifications',
            subtitle: 'Receive important alerts and updates',
            leading: Icon(Icons.notifications, color: Colors.green),
            onChange: (value) {
              print('Notifications: $value');
            },
          ),
          SimpleSettingsTile(
            title: 'Change Password',
            leading: Icon(Icons.lock, color: Colors.orange),
            subtitle: 'Update your account password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePasswordPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ChangePasswordPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter your new password:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextInputSettingsTile(
              settingKey: AccountPage.keyPassword,
              obscureText: true,
              title: 'New Password',
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: change password functionality
              },
              child: Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}