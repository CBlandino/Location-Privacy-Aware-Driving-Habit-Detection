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
import 'previous_trips_page.dart';
import 'trip_helper.dart';
import 'user_lookup.dart';
import 'user_score_page.dart';
import 'user_trips_page.dart';

class HomePage extends StatefulWidget {
  String role;
  bool isLoading = true;

  HomePage({required this.role});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  File? _profileImage;

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _searchError = '';
  String _searchedUserId = '';
  List<Map<String, dynamic>> _userTrips = [];
  Map<String, dynamic>? _userScore;

  late String role;
  late String email;
  late String firstName;
  late String lastName;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Switches pages
    });
  }

  List<dynamic> recentTrips = [];
  String errorMessage = '';
  bool isLoading = false;

  void _searchUsers(String query) async {
    setState(() {
      _isSearching = true;
      _searchError = '';
      _searchResults = [];
    });

    try {
      // Replace this with your real API
      // Example: simulate an API call delay
      await Future.delayed(Duration(seconds: 1));

      // For demonstration: pretend we found a user with a matching ID
      final results =
          [
                {'id': '123', 'name': 'John Doe'},
                {'id': '456', 'name': 'Jane Smith'},
              ]
              .where(
                (user) =>
                    user['name']!.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

      setState(() {
        _isSearching = false;
        _searchResults = results;
        _searchedUserId = (results.isNotEmpty ? results.first['id'] : '')!;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchError = 'Search failed: $e';
      });
    }
  }

  Future<void> loadRecentTrips() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      List<dynamic> trips = await TripService.fetchPreviousTrips();
      setState(() {
        recentTrips = trips.take(3).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading trips: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load recent trips';
      });
    }
  }

  Future<void> _loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    //Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);

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
    _checkAuthToken();
    //_loadUserInfo();
    loadRecentTrips();
    _loadProfileImage();
  }

  Future<void> _checkAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token != null) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      role = decodedToken['role'];
      firstName = decodedToken['first_name'];
      lastName = decodedToken['last_name'];
      email = decodedToken['email'];

      setState(() {
        isLoading = false;
      });

      print('Decoded: $firstName $lastName ($email), Role: $role');

      // store them in SharedPreferences
      await prefs.setString('role', role);
      await prefs.setString('first_name', firstName);
      await prefs.setString('last_name', lastName);
      await prefs.setString('email', email);
    } else {
      print('No token found in SharedPreferences');
    }
  }

  // Future<void> _loadUserInfo() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();

  //   role = prefs.getString('role')!;
  //   firstName = prefs.getString('first_name') ?? 'First';
  //   lastName = prefs.getString('last_name') ?? 'Last';
  //   email = prefs.getString('email')?? 'Email';

  // }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(radius: 30, child: Icon(Icons.business)),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, Insurance Provider!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Manage your users and their data',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
            if (description != null) SizedBox(height: 10),
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
            'Recent Trips',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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
                  : recentTrips.isEmpty
                      ? Center(
                          child: Text(
                            'No recent trips available.',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        )
                      : Column(
                          children: recentTrips.take(3).map((trip) {
                            return Container(
                              margin: EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[700],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.directions_car,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  TripService.formatTimestamp(trip['start_time'] ?? trip['timestamp']),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  '${trip['distance'].toStringAsFixed(2)} miles',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.chevron_right,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    
    TripService.showTripDetails(context, trip);
                                  },
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
        ],
      ),
    ),
  );
}


  Widget _buildUserTripsPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Expanded(
      child: Column(
        children: [
          Text(
            'User Trip Lookup',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              labelText: 'Enter User ID',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  // TODO: Implement trip lookup
                },
              ),
            ),
          ),
          SizedBox(height: 20),
          // TODO: Add trip results display
          Expanded(
            child: Center(child: Text('Search for a user to view their trips')),
          ),
        ],
      )
      ),
    );
  }

  Widget _buildUserScorePage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'User Score Lookup',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              labelText: 'Enter User ID',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  // TODO: Implement score lookup
                },
              ),
            ),
          ),
          SizedBox(height: 20),
          // TODO: Add score display
          Expanded(
            child: Center(child: Text('Search for a user to view their score')),
          ),
        ],
      ),
    );
  }

Widget _buildInsuranceHomePage() {
  return _selectedIndex == 0
      ? SingleChildScrollView(
          child: Padding(
            padding:  const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Welcome Card with gradient
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade700, Colors.blue.shade400],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                    
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Icon(Icons.business, color: Colors.white, size: 30),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, Insurance Provider!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Manage your users and their driving data',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // User Lookup Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.search, color: Colors.blue.shade700),
                          SizedBox(width: 8),
                          Text(
                            'User Lookup',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                       SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: UserLookupPage(
                        onSearch: _searchUsers,
                        searchResults: _searchResults,
                        isLoading: _isSearching,
                        errorMessage: _searchError,
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ))
      : _selectedIndex == 1
          ? SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Welcome Card
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue.shade700, Colors.blue.shade400],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Icon(Icons.business, color: Colors.white, size: 30),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User Trip Data',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'View and analyze user trip history',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // User Trips Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.directions_car, color: Colors.blue.shade700),
                              SizedBox(width: 8),
                              Text(
                                'User Trips',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          UserTripsPage(
                            userId: _searchedUserId,
                            trips: _userTrips,
                            isLoading: false,
                            errorMessage: '',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ))
          : _selectedIndex == 2
              ? SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Welcome Card
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.blue.shade700, Colors.blue.shade400],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Icon(Icons.business, color: Colors.white, size: 30),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'User Safety Scores',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Review and analyze user driving scores',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // User Score Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.assessment, color: Colors.blue.shade700),
                                  SizedBox(width: 8),
                                  Text(
                                    'User Score',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              UserScorePage(
                                userId: _searchedUserId,
                                scoreData: _userScore ?? {},
                                isLoading: false,
                                errorMessage: '',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
              : SettingsPage();
}

Widget _buildUserHomePage() {
  String displayName = '$firstName $lastName' ?? 'User';
  String initials = (firstName.isNotEmpty && lastName.isNotEmpty)
      ? '${firstName[0]}${lastName[0]}'.toUpperCase()
      : '??';

  return _selectedIndex == 0
      ? SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with welcome and profile
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue.shade300,
                        backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null
                            ? Text(
                                initials,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),

                // Start Trip Button
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CurrentTripPage()),
                      );
                    },
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.blue.shade700, Colors.blue.shade400],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_car,
                              size: 48,
                              color: Colors.white,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Start Trip",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),

                // Recent Trips Section
                Text(
                  'Recent Trips',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 16),
                _buildPreviousTripsSection(),
                SizedBox(height: 24),

                // Score Section
                Text(
                  'Your Safety Score',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.blue.shade50, Colors.white],
                      ),
                      border: Border.all(color: Colors.blue.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, size: 40, color: Colors.amber),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'View your score',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Check your latest driving safety assessment',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.blue.shade400),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      : SettingsPage();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          isLoading
              ? null
              : CustomAppBar(
                selectedIndex: _selectedIndex,
                onItemTapped: _onItemTapped,
                role: widget.role, // Pass the role
              ),
      drawer: isLoading ? null : CustomDrawer(role: widget.role),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : widget.role == 'user'
              ? _buildUserHomePage()
              : _buildInsuranceHomePage(),
      bottomNavigationBar:
          isLoading
              ? null
              : CustomAppBar(
                selectedIndex: _selectedIndex,
                onItemTapped: _onItemTapped,
                role: widget.role, // Pass the role
              ).buildBottomNavBar(context),
    );
  }
}
