import 'dart:io';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'ipconfig.dart';
import 'custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'custom_drawer.dart'; // Import CustomDrawer
import 'current_trip_page.dart'; // For navigation to CurrentTripPage
import 'settings_page.dart';
import 'trip_helper.dart';

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

String _searchQuery = '';
List<Map<String, dynamic>> _foundUsers = [];
Map<String, dynamic>? _selectedUser;
bool _isLoadingUsers = false;
bool _isLoadingScore = false;
bool _isLoadingTrips = false;
String _tripSortOption = 'recent'; // 'recent' or 'distance

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

Future<void> _searchForUsers() async {
  if (_searchQuery.isEmpty) return;
  
  setState(() {
    _isLoadingUsers = true;
    _foundUsers = [];
    _selectedUser = null;
  });

  try {
    final results = await TripService.searchUsers(_searchQuery);
    setState(() {
      _foundUsers = results;
      _isLoadingUsers = false;
    });
  } catch (e) {
    setState(() {
      _isLoadingUsers = false;
      _searchError = 'Search failed: $e';
    });
  }
}

Future<void> _loadUserScore(String userId) async {
  setState(() {
    _isLoadingScore = true;
    _userScore = null;
  });

  try {
    final scoreData = await TripService.getUserScore(userId);
    setState(() {
      _userScore = scoreData;
      _isLoadingScore = false;
    });
  } catch (e) {
    setState(() {
      _isLoadingScore = false;
      _searchError = 'Failed to load score: $e';
    });
  }
}

Future<void> _loadUserTrips(String userId) async {
  setState(() {
    _isLoadingTrips = true;
    _userTrips = [];
  });

  try {
    final trips = await TripService.getUserTrips(userId, sortBy: _tripSortOption);
    setState(() {
      _userTrips = trips;
      _isLoadingTrips = false;
    });
  } catch (e) {
    setState(() {
      _isLoadingTrips = false;
      _searchError = 'Failed to load trips: $e';
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

  void _selectUser(Map<String, dynamic> user) {
  setState(() {
    _selectedUser = user;
    _searchedUserId = user['id'];
  });
  _loadUserScore(user['id']);
  _loadUserTrips(user['id']);
}

void _setTripSort(String sortOption) {
  setState(() {
    _tripSortOption = sortOption;
  });
  if (_searchedUserId.isNotEmpty) {
    _loadUserTrips(_searchedUserId);
  }
}

  Future<void> _loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

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

Widget _buildPreviousTripsSection() {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
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

  Widget _buildUserSearchCard({bool showCloseButton = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCloseButton)
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 8),
                Text(
                  'Search Users',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          if (!showCloseButton)
            Text(
              'Find User',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Search by name, email or ID',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: _searchForUsers,
              ),
            ),
            onChanged: (value) => _searchQuery = value,
            onSubmitted: (_) => _searchForUsers(),
          ),
          SizedBox(height: 16),
          if (_isLoadingUsers)
            Center(child: CircularProgressIndicator())
          else if (_foundUsers.isNotEmpty)
            Column(
              children: [
                Text(
                  'Search Results',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                ..._foundUsers.map((user) => ListTile(
                  leading: CircleAvatar(
                    child: Text(user['name'][0]),
                  ),
                  title: Text(user['name']),
                  subtitle: Text(user['email']),
                  onTap: () {
                    _selectUser(user);
                    if (showCloseButton) Navigator.pop(context);
                  },
                )).toList(),
              ],
            ),
        ],
      ),
    );
  }

Widget _buildUserScoreCard() {
  return Card(
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
              Text(
                'User Safety Score',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              if (_selectedUser != null) ...[
                SizedBox(width: 8),
                Chip(
                  label: Text(_selectedUser!['name']),
                ),
              ],
            ],
          ),
          SizedBox(height: 16),
          if (_isLoadingScore)
            Center(child: CircularProgressIndicator())
          else if (_userScore == null)
            Center(child: Text('Select a user to view their score'))
          else
            Column(
              children: [
                CircularProgressIndicator(
                  value: _userScore!['score'] / 100,
                  semanticsLabel: 'Safety score',
                ),
                SizedBox(height: 16),
                Text(
                  '${_userScore!['score']}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Last updated: ${TripService.formatTimestamp(_userScore!['updated_at'])}',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

Widget _buildUserTripsCard() {
  return Card(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Trips',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              DropdownButton<String>(
                value: _tripSortOption,
                items: [
                  DropdownMenuItem(
                    value: 'recent',
                    child: Text('Recent'),
                  ),
                  DropdownMenuItem(
                    value: 'distance',
                    child: Text('Longest'),
                  ),
                ],
                onChanged: (value) => _setTripSort(value!),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_isLoadingTrips)
            Center(child: CircularProgressIndicator())
          else if (_userTrips.isEmpty)
            Center(child: Text(_selectedUser == null 
                ? 'Select a user to view trips'
                : 'No trips found'))
          else
            Column(
              children: _userTrips.map((trip) => ListTile(
                leading: Icon(Icons.directions_car),
                title: Text(TripService.formatTimestamp(trip['start_time'])),
                subtitle: Text('${trip['distance'].toStringAsFixed(2)} miles'),
                trailing: IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () => TripService.showTripDetails(context, trip),
                ),
              )).toList(),
            ),
        ],
      ),
    ),
  );
}

Widget _buildWelcomeCard({required String title, required String description}) {
  return Container(
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
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
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
  );
}

  Widget _buildAdminHomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildWelcomeCard(
              title: 'Admin Dashboard',
              description: 'Manage users, insurance companies, and server status',
            ),
            SizedBox(height: 16),
            
            // Server Status - using _buildServerStatusCard()
            _buildServerStatusCard(),
            SizedBox(height: 16),
            
            // Quick Actions Grid
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildAdminActionCard(
                  icon: Icons.person_add,
                  title: 'Create Account',
                  onTap: () => _showCreateAccountModal(),
                ),
                _buildAdminActionCard(
                  icon: Icons.search,
                  title: 'Search Users',
                  onTap: () => _showUserSearch(),
                ),
                _buildAdminActionCard(
                  icon: Icons.business,
                  title: 'Search Insurance',
                  onTap: () => _showInsuranceSearch(),
                ),
                _buildAdminActionCard(
                  icon: Icons.analytics,
                  title: 'View Analytics',
                  onTap: () => _showAnalytics(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAnalytics() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: _buildAnalyticsCard(),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(width: 8),
              Text(
                'Analytics Dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Platform Usage',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text('Usage charts will appear here')),
          ),
          SizedBox(height: 16),
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: 8),
          ...List.generate(5, (index) => ListTile(
            leading: Icon(Icons.notifications, color: Colors.blue),
            title: Text('System notification ${index + 1}'),
            subtitle: Text('2${index} minutes ago'),
          )),
        ],
      ),
    );
  }

void _showCreateAccountModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: _buildCreateAccountCard(),
          );
        },
      ),
    );
  }

  void _showUserSearch() {
    setState(() {
      _searchQuery = '';
      _foundUsers = [];
      _selectedUser = null;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: _buildUserSearchCard(showCloseButton: true),
          );
        },
      ),
    );
  }

  void _showInsuranceSearch() {
    setState(() {
      _searchQuery = '';
      _foundUsers = [];
      _selectedUser = null;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: _buildInsuranceSearchCard(showCloseButton: true),
          );
        },
      ),
    );
  }

Widget _buildAdminActionCard({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.blue.shade700),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildServerStatusCard() {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Server Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: 16),
          FutureBuilder<bool>(
            future: _checkServerStatus(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error checking server status'));
              }
              return Row(
                children: [
                  Icon(
                    snapshot.data == true ? Icons.check_circle : Icons.error,
                    color: snapshot.data == true ? Colors.green : Colors.red,
                    size: 40,
                  ),
                  SizedBox(width: 16),
                  Text(
                    snapshot.data == true 
                      ? 'Server is online and running'
                      : 'Server is offline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

  Widget _buildInsuranceSearchCard({bool showCloseButton = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCloseButton)
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 8),
                Text(
                  'Search Insurance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          if (!showCloseButton)
            Text(
              'Find Insurance Company',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Search by name, state or ID',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: _searchForInsurance,
              ),
            ),
            onChanged: (value) => _searchQuery = value,
            onSubmitted: (_) => _searchForInsurance(),
          ),
          SizedBox(height: 16),
          if (_isLoadingUsers)
            Center(child: CircularProgressIndicator())
          else if (_foundUsers.isNotEmpty)
            Column(
              children: [
                Text(
                  'Search Results',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                ..._foundUsers.map((user) => ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.business),
                  ),
                  title: Text(user['name']),
                  subtitle: Text(user['state']),
                  onTap: () {
                    _selectUser(user);
                    if (showCloseButton) Navigator.pop(context);
                  },
                )).toList(),
              ],
            ),
        ],
      ),
    );
  }

Widget _buildCreateAccountCard() {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _serverNumberController = TextEditingController();
  
  bool _isCreating = false;
  String _selectedRole = 'user';

  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            SizedBox(width: 8),
            Text(
              'Create New Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'insurance', child: Text('Insurance Company')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              if (_selectedRole == 'user') ...[
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter first name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter last name';
                    }
                    return null;
                  },
                ),
              ],
              if (_selectedRole == 'insurance') ...[
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'Company Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter company name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter state';
                    }
                    return null;
                  },
                ),
              ],
              if (_selectedRole == 'admin') ...[
                TextFormField(
                  controller: _serverNumberController,
                  decoration: InputDecoration(
                    labelText: 'Server Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter server number';
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreating 
                    ? null 
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isCreating = true);
                          try {
                            switch (_selectedRole) {
                              case 'admin':
                                await TripService.createAdminAccount(
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                  serverNumber: _serverNumberController.text,
                                );
                                break;
                              case 'insurance':
                                await TripService.createInsuranceAccount(
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                  companyName: _firstNameController.text,
                                  state: _lastNameController.text,
                                );
                                break;
                              case 'user':
                              default:
                                await TripService.createUserAccount(
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                  firstName: _firstNameController.text,
                                  lastName: _lastNameController.text,
                                );
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Account created successfully')),
                            );
                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error creating account: $e')),
                            );
                          } finally {
                            setState(() => _isCreating = false);
                          }
                        }
                      },
                  child: _isCreating 
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text('Create Account'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<bool> _checkServerStatus() async {
  return await TripService.checkServerStatus();
}

Future<void> _searchForInsurance() async {
  if (_searchQuery.isEmpty) return;
  
  setState(() {
    _isLoadingUsers = true;
    _foundUsers = [];
    _selectedUser = null;
  });

  try {
    final results = await TripService.searchInsurance(_searchQuery);
    setState(() {
      _foundUsers = results;
      _isLoadingUsers = false;
    });
  } catch (e) {
    setState(() {
      _isLoadingUsers = false;
      _searchError = 'Search failed: $e';
    });
  }
}


Widget _buildInsuranceHomePage() {
  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildWelcomeCard(
            title: 'Insurance Dashboard',
            description: 'Manage user data and driving scores',
          ),
          SizedBox(height: 24),
          _buildUserSearchCard(),
          SizedBox(height: 24),
          _buildUserScoreCard(),
          SizedBox(height: 24),
          _buildUserTripsCard(),
        ],
      ),
    ),
  );
}

Widget _buildUserHomePage() {
  String displayName = '$firstName $lastName';
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
      appBar: isLoading
          ? null
          : CustomAppBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
              role: widget.role,
            ),
      drawer: isLoading ? null : CustomDrawer(role: widget.role),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : widget.role == 'user'
              ? _buildUserHomePage()
              : widget.role == 'insurance'
                  ? _buildInsuranceHomePage()
                  : _buildAdminHomePage(),
      bottomNavigationBar: isLoading
          ? null
          : CustomAppBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
              role: widget.role,
            ).buildBottomNavBar(context),
    );
  }
}
