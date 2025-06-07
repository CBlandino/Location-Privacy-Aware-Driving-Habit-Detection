import 'package:flutter/material.dart';
import 'login_page.dart'; // Import for LoginPageWidget navigation



// No Longer in Use




// AccountSettingsPage provides a simple interface for account management.
// Currently contains only logout functionality but can be expanded with more settings.
class AccountSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set white background for clean appearance
      backgroundColor: Colors.white,
      
      // AppBar with title and blue background
      appBar: AppBar(
        title: Text('Account Settings'),
        backgroundColor: Colors.blue.shade700,
      ),
      
      // Main content area with padding
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          
          // Stretch children to full width
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Page title
            Text(
              'Account Settings',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            
            // Spacer between title and button
            SizedBox(height: 20),
            
            // Logout button with custom styling
            ElevatedButton(
              onPressed: () {

                // Logout action - navigates to login page and clears navigation stack
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPageWidget()),

                  // Clears all previous routes
                  (route) => false, 
                );
              },
              child: Text('Logout'),
              style: ElevatedButton.styleFrom(
                // Custom green color
                backgroundColor: Color(0xFF7AC143), 

                // Vertical padding
                padding: EdgeInsets.symmetric(vertical: 15), 

                // Text size
                textStyle: TextStyle(fontSize: 16), 

                // Rounded corners
                shape: RoundedRectangleBorder( 
                  borderRadius: BorderRadius.circular(30),
                ),

                // Shadow depth
                elevation: 5, 
              ),
            ),
          ],
        ),
      ),
    );
  }
}