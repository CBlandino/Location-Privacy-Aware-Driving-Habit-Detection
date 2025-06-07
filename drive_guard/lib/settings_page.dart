import 'dart:io';
import 'package:drive_guard/about_page.dart';
import 'package:drive_guard/appearance_page.dart';
import 'package:drive_guard/helpSupport_page.dart';
import 'package:drive_guard/privacySecurity_page.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_app_bar.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'account_page.dart';
import 'notifications_page.dart';

class SettingsPage extends StatefulWidget {

  @override
  _SettingsPage createState() => _SettingsPage();
}

class _SettingsPage extends State<SettingsPage>
{
late String role;
bool isLoading = true;

int _selectedIndex = 3;

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index; // Switches pages     
      });
    }

 @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

Future<void> _loadUserInfo() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  role = prefs.getString('role')!;
  //String? firstName = prefs.getString('first_name');
  //String? lastName = prefs.getString('last_name');
  //String? email = prefs.getString('email');
   setState((){
      isLoading = false;
  });


}

@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      // Navigate back to HomePage instead of the last screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(role: role)), // Pass role 
      );
      return false; // Prevent default back navigation
    },
    
    child: Scaffold(
      appBar: isLoading
          ? null
          : CustomAppBar(
        selectedIndex: 3, // Assuming index 3 is the "Settings" page
        onItemTapped: _onItemTapped,
        role: role,
      ),

      body: isLoading
            ? Center(child: CircularProgressIndicator())
            : Stack(
        children: [
          SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Makes tiles same color as background
                      Theme(
                        data: Theme.of(context).copyWith(
                          listTileTheme: ListTileThemeData(
                            tileColor: Colors.white,
                          ),
                        ),
                        child: SettingsGroup(
                          title: 'SETTINGS',
                          children: <Widget>[
                            const SizedBox(height: 8),
                            AccountPage(),
                            NotificationsPage(),
                            AppearancePage(),
                            PrivSecPage(),
                            HelpSupportPage(),
                            AboutPage(),
                            // buildReviewDriving(context),
                            // buildReportBug(context),
                            // buildsendFeedback(context),
                            buildLogout(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar from CustomAppBar
      bottomNavigationBar: isLoading
          ? null
          : CustomAppBar(
        selectedIndex: 3, // Keep this in sync with settings page index
        onItemTapped: _onItemTapped,
        role:role,
      ).buildBottomNavBar(context),
    )
  );
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

 // void setState(Null Function() param0) {}


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
}
