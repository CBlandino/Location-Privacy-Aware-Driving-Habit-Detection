import 'dart:io';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'ipconfig.dart';
import 'custom_app_bar.dart';
import 'login_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'custom_drawer.dart'; // Import CustomDrawer
import 'current_trip_page.dart'; // For navigation to CurrentTripPage
import 'previous_trips_page.dart';
import 'score_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final String role;

  HomePage({required this.role});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
    int _selectedIndex = 0;
    File? _profileImage;

    final List<Widget> _pages = [
      // HomePage(),      // Home Dashboard
      CurrentTripPage(),    // Current Trip
      PreviousTripsPage(),  // Previous Trips
      ScorePage(),          // Score Page
      SettingsPage(),        // Account Page
    ];

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index; // Switches pages     
      });
    }


  List<dynamic> trips = [];
  bool isLoading = true;
  String errorMessage = '';

Future<void> _loadTrips() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');
  Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);

  // if (JwtDecoder.isExpired(token)) {
  //   setState(() {
  //     errorMessage = 'Unauthorized access. Please log in again.';
  //     isLoading = false;
  //   });
  //   Navigator.pushReplacement(
  //   context,
  //   MaterialPageRoute(builder: (context) => LoginPageWidget()), // Redirect to login
  //   );
  //   return;
  // }

  try {
    final response = await http.get(
      Uri.parse(AppConfig.server),
      headers: {
        'Authorization': 'Bearer $token', // Include the token
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        trips = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = 'Failed to load trips. Please try again later.';
        isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      errorMessage = 'Error loading trips: $e';
      isLoading = false;
    });
  }
}

Future<void> _loadProfileImage() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');
  Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);

  // if (JwtDecoder.isExpired(token)) {
  //   Navigator.pushReplacement(
  //   context,
  //   MaterialPageRoute(builder: (context) => LoginPageWidget()), // Redirect to login
  //   );
  //   return;
  // }

  final imagePath = prefs.getString('profile_image');
  if (imagePath != null) {
    setState(() {
      _profileImage = File(imagePath);
    });
  }
}

  @override
  void initState() {
    super.initState();
    _loadTrips();
    _loadProfileImage();
    _checkAuthToken();
  }

Future<void> _checkAuthToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');
  Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);

  // if (JwtDecoder.isExpired(token)) {
  //   Navigator.pushReplacement(
  //   context,
  //   MaterialPageRoute(builder: (context) => LoginPageWidget()), // Redirect to login
  //   );
  // }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: CustomAppBar(
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
    ),
    drawer: CustomDrawer(role: widget.role),
    body: _selectedIndex == 0
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 50),
                      Expanded(
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                'Welcome to Your Dashboard',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                'John Doe!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Profile Image or Initials
                      Align(
                        alignment: Alignment.centerRight,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blue[300],
                          backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                          child: _profileImage == null
                              ? Text(
                                  'JD', // Replace with user's initials dynamically
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 60),

                  // Start Trip Button
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.blue.shade700, Colors.blue.shade400],
                        ),
                      ),
                      child: RawMaterialButton(
                        onPressed: () {
                          setState(() {
                            _selectedIndex = 0;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CurrentTripPage()),
                          );
                        },
                        shape: CircleBorder(),
                        elevation: 5.0,
                        fillColor: Colors.transparent, // Transparent to let gradient show
                        padding: const EdgeInsets.all(95.0),
                        child: Text(
                          "Start Trip",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 60),

                  // Section with Previous Trips and Score
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 1, 84, 143),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: Offset(0, 4), // Soft shadow
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 30),
                        _buildPreviousTripsSection(),
                        SizedBox(height: 30),
                        _buildSection(
                          title: 'Score',
                          icon: Icons.star,
                          buttonText: 'Check Score',
                          onTap: () {
                            setState(() {
                              _selectedIndex = 2;
                            });
                          },
                        ),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : _pages[_selectedIndex], // Switch to other pages dynamically

    // Use the CustomAppBar's bottom navigation bar
    bottomNavigationBar: CustomAppBar(
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
    )
    .buildBottomNavBar(context),
  );
}

  Widget _buildSection({
    required String title,
    required IconData icon,
    required String buttonText,
    String? description,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 10,
      color: Colors.blue.withOpacity(.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: Icon(icon, color: Colors.white, size: 40),
              title: Text(
                title,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              trailing: ElevatedButton(
                onPressed: onTap,
                child: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            if (description != null)
              SizedBox(height: 10),
            if (description != null)
              Text(
                description,
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  
  }

  Widget _buildPreviousTripsSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 10,
      color: Colors.lightBlueAccent,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Previous Trips',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 10),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Text(
                          errorMessage,
                          style: TextStyle(color: Colors.red, fontSize: 18),
                        ),
                      )
                    : trips.isEmpty
                        ? Center(
                            child: Text(
                              'No previous trips available.',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          )
                        : Column(
                            children: List.generate(
                              trips.length > 3 ? 3 : trips.length,
                              (index) {
                                var trip = trips[index];
                                return ListTile(
                                  tileColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  title: Text('Trip ${trip['id']}'),
                                  subtitle: Text('Duration: ${trip['duration']} minutes\nDate: ${trip['date']}'),
                                  trailing: Icon(Icons.arrow_forward),
                                  onTap: () {},
                                );
                              },
                            ),
                          ),
          ],
        ),
      ),
    );
  }
}
