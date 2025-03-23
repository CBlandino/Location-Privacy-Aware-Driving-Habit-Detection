import 'dart:io';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart'; // Ensure LoginPage is imported
import 'account_page.dart';

class SettingsPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Settings',
          ),
        backgroundColor: Colors.blue[500],
      ),
      
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      SettingsGroup(
                        title: 'GENERAL',
                        children: <Widget>[
                          const SizedBox(height: 8),
                          AccountPage(),
                          buildReviewDriving(context),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SettingsGroup(
                        title: 'FEEDBACK',
                        children: <Widget>[
                          const SizedBox(height: 8),
                          buildReportBug(context),
                          buildsendFeedback(context),
                        ],
                      ),
                    ],
                  ),
                ),
                buildLogout(context), 
                SizedBox(height: 20), 
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget buildAccountSettings() => SimpleSettingsTile(
//   leading: Icon(
//     Icons.person,
//     color: Colors.blue[100],
//     ),
//   title: 'Account Settings',
//   subtitle: 'Privacy, Security, Language',
//   child: Container(),
//   onTap: () {
//   },
// );

Widget buildLogout(BuildContext context) => SimpleSettingsTile(
  title: 'Logout',
  leading: Icon(
    Icons.logout,
    color: Colors.redAccent,
  ),
  subtitle: '',
  onTap: () async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); // Remove stored authentication token

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPageWidget()),
      (route) => false, // Remove all previous routes
    );
  },
);

Widget buildReportBug(BuildContext context) => SimpleSettingsTile(
  title: 'Report A Bug',
  subtitle: '',
  leading: Icon(
    Icons.bug_report,
    color: Colors.purple[400],
  ),
  onTap:() {
    
  },
);

Widget buildsendFeedback(BuildContext context) => SimpleSettingsTile(
  title: 'Send Feedback',
  subtitle: '',
  leading: Icon(
    Icons.thumbs_up_down,
    color: Colors.orange[700],
  ),
  onTap: () {
    
  },
);

Widget buildReviewDriving(BuildContext context) => SimpleSettingsTile(
  title: 'Review Driving',
  subtitle: 'Score, Trips, Habits',
  leading: Icon(
    Icons.privacy_tip,
    color: Colors.red,
  ),
  onTap: () {
      
  },
);


      // backgroundColor: Colors.white,
      // appBar: AppBar(
      //   title: Text('Account Settings'),
      //   backgroundColor: Colors.blue.shade700,
      // ),
      // body: Padding(
      //   padding: const EdgeInsets.all(20),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.stretch,
      //     children: [
      //       Text(
      //         'Account Settings',
      //         style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      //       ),
      //       SizedBox(height: 20),
      //       ElevatedButton(
      //         onPressed: () {
      //           // Implement logout functionality
      //           Navigator.pushAndRemoveUntil(
      //             context,
      //             MaterialPageRoute(builder: (context) => LoginPageWidget()),
      //             (route) => false, // Remove all previous routes
      //           );
      //         },
      //         child: Text('Logout'),
      //         style: ElevatedButton.styleFrom(
      //           backgroundColor: Color(0xFF7AC143), // Accent color for buttons
      //           padding: EdgeInsets.symmetric(vertical: 15),
      //           textStyle: TextStyle(fontSize: 16),
      //           shape: RoundedRectangleBorder(
      //             borderRadius: BorderRadius.circular(30),
      //           ),
      //           elevation: 5,
      //         ),
      //       ),
      //     ],
      //   ),
      // ),