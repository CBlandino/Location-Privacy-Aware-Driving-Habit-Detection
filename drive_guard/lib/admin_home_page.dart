import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;
import 'ipconfig.dart';
import 'trip_helper.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String _searchedUserId = '';
    Map<String, dynamic>? _userScore;
  String _tripSortOption = 'recent';
   List<Map<String, dynamic>> _userTrips = [];
  String _searchQuery = '';
  List<Map<String, dynamic>> _foundUsers = [];
  String _searchError = '';
  Map<String, dynamic>? _selectedUser;
  bool _isLoadingUsers = false;
bool _isLoadingScore = false;
bool _isLoadingTrips = false;

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(isWeb ? 32 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 1400,
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(isWeb: isWeb),
                    SizedBox(height: isLargeScreen ? 40 : 24),

                    // Quick Stats Row - Responsive layout
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                        maxWidth: constraints.maxWidth,
                      ),
                      child: _buildQuickStatsRow(),
                    ),
                    SizedBox(height: isLargeScreen ? 40 : 24),

                    // GridView - Different layout for mobile
                    if (isLargeScreen) 
                      SizedBox(
                        height: 500,
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          children: _buildActionCards(),
                        ),
                      )
                    else
                      Column(
                        children: _buildActionCards()
                            .map((card) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: card,
                                ))
                            .toList(),
                      ),

                    SizedBox(height: isLargeScreen ? 40 : 24),
                    _buildServerStatusCard(isWeb: isWeb),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

   Widget _buildWebGrid() {
    return SizedBox(
      height: 500,
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        physics: const NeverScrollableScrollPhysics(),
        children: _buildActionCards(),
      ),
    );
  }

    Widget _buildMobileGrid() {
    return Column(
      children: _buildActionCards()
          .map((card) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: card,
              ))
          .toList(),
    );
  }

 
  List<Widget> _buildActionCards() {
    return [
      _buildAdminActionCard(
        icon: Icons.person_add,
        title: 'Create Account',
        description: 'Register new users, admins, or insurance companies',
        color: Colors.blue,
        onTap: () => _showCreateAccountModal(),
        isWeb: kIsWeb,
      ),
      _buildAdminActionCard(
        icon: Icons.search,
        title: 'Search Users',
        description: 'Find and manage user accounts',
        color: Colors.green,
        onTap: () => _showUserSearch(),
        isWeb: kIsWeb,
      ),
      _buildAdminActionCard(
        icon: Icons.business,
        title: 'Search Insurance',
        description: 'Manage insurance company accounts',
        color: Colors.orange,
        onTap: () => _showInsuranceSearch(),
        isWeb: kIsWeb,
      ),
      _buildAdminActionCard(
        icon: Icons.analytics,
        title: 'View Analytics',
        description: 'System usage and activity reports',
        color: Colors.purple,
        onTap: () => _showAnalytics(),
        isWeb: kIsWeb,
      ),
    ];
  }

  void _showAnalytics() {
  final isWeb = kIsWeb;
  
  if (isWeb) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 800,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Dialog(
            insetPadding: EdgeInsets.all(20),
            child: _buildAnalyticsCard(isWeb: true),
          ),
        ),
      ),
    );
  } else {
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
            child: _buildAnalyticsCard(isWeb: false),
          );
        },
      ),
    );
  }
}



  Widget _buildWelcomeCard({required bool isWeb}) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: double.infinity,
      ),
      child: Card(
        elevation: isWeb ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
        ),
        child: Container(
          padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade700, Colors.blue.shade400],
            ),
            borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.dashboard,
                size: isLargeScreen ? 48 : 36,
                color: Colors.white,
              ),
              SizedBox(width: isLargeScreen ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        fontSize: isLargeScreen ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isLargeScreen ? 8 : 4),
                    Text(
                      'Manage users, insurance companies, and system status',
                      style: TextStyle(
                        fontSize: isLargeScreen ? 16 : 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchQuickStats() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.server}/quickstats'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load stats: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to connect to server: $e');
  }
}

  Widget _buildQuickStatsRow() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchQuickStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Failed to load stats'),
            ),
          );
        }

        final stats = snapshot.data ?? {
          'total_users': 0,
          'insurance_companies': 0,
          'active_trips': 0,
          'average_score': 0,
        };

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.people, 'Total Users', 
                    stats['total_users'].toString(), Colors.blue),
                  SizedBox(width: 16),
                  _buildStatItem(Icons.business, 'Insurance Cos', 
                    stats['insurance_companies'].toString(), Colors.green),
                  SizedBox(width: 16),
                  _buildStatItem(Icons.directions_car, 'Active Trips', 
                    stats['active_trips'].toString(), Colors.orange),
                  SizedBox(width: 16),
                  _buildStatItem(Icons.assessment, 'Avg. Score', 
                    '${stats['average_score']}%', Colors.purple),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 120,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
  
Widget _buildServerStatusCard({required bool isWeb}) {
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

  Widget _buildAdminActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    required bool isWeb,
  }) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: isLargeScreen ? 300 : double.infinity,
        maxWidth: isLargeScreen ? 500 : double.infinity,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Card(
          elevation: isWeb ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
              height: isLargeScreen ? 200 : 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 8 : 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, 
                      size: isLargeScreen ? 24 : 20, 
                      color: color),
                  ),
                  SizedBox(height: isLargeScreen ? 12 : 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isLargeScreen ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isLargeScreen ? 4 : 2),
                  Expanded(
                    child: Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isLargeScreen ? 14 : 12,
                      ),
                    ),
                  ),
                  if (isLargeScreen) 
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.arrow_forward, 
                        size: 20, 
                        color: color),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

void _showCreateAccountModal() {
  final isWeb = kIsWeb;
  
  if (isWeb) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 800,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Dialog(
            insetPadding: EdgeInsets.all(20),
            child: _buildCreateAccountCard(isWeb: true),
          ),
        ),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: _buildCreateAccountCard(isWeb: false),
            );
          },
        ),
      ),
    );
  }
}

Widget _buildCreateAccountCard({required bool isWeb}) {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _serverNumberController = TextEditingController();
  
  bool _isCreating = false;
  String _selectedRole = 'user';

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    padding: EdgeInsets.all(isWeb ? 32 : 24),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Create New Account',
                style: TextStyle(
                  fontSize: isWeb ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey[700]),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: isWeb ? 24 : 16),
          
          // Role Selection
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: 'Account Type',
                labelStyle: TextStyle(
                  color: Colors.blue[800],
                  fontSize: isWeb ? 16 : 14,
                ),
              ),
              style: TextStyle(
                color: Colors.black,
                fontSize: isWeb ? 16 : 14,
              ),
              dropdownColor: Colors.white,
              icon: Icon(Icons.arrow_drop_down, color: Colors.blue[800]),
              items: [
                DropdownMenuItem(
                  value: 'user',
                  child: Text('User Account'),
                ),
                DropdownMenuItem(
                  value: 'insurance',
                  child: Text('Insurance Company'),
                ),
                DropdownMenuItem(
                  value: 'admin',
                  child: Text('Admin Account'),
                ),
              ],
              onChanged: (value) => setState(() => _selectedRole = value!),
            ),
          ),
          SizedBox(height: isWeb ? 24 : 16),
          
          // Form Fields
          Column(
            children: [
              // Email Field
              _buildFormField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                isWeb: isWeb,
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
              SizedBox(height: isWeb ? 20 : 16),
              
              // Password Field
              _buildFormField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock,
                isWeb: isWeb,
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
              SizedBox(height: isWeb ? 20 : 16),
              
              // Dynamic Fields Based on Role
              if (_selectedRole == 'user') ...[
                _buildFormField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person,
                  isWeb: isWeb,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter first name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: isWeb ? 20 : 16),
                _buildFormField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline,
                  isWeb: isWeb,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter last name';
                    }
                    return null;
                  },
                ),
              ],
              
              if (_selectedRole == 'insurance') ...[
                _buildFormField(
                  controller: _firstNameController,
                  label: 'Company Name',
                  icon: Icons.business,
                  isWeb: isWeb,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter company name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: isWeb ? 20 : 16),
                _buildFormField(
                  controller: _lastNameController,
                  label: 'State',
                  icon: Icons.location_on,
                  isWeb: isWeb,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter state';
                    }
                    return null;
                  },
                ),
              ],
              
              if (_selectedRole == 'admin') ...[
                _buildFormField(
                  controller: _serverNumberController,
                  label: 'Server Number',
                  icon: Icons.dns,
                  isWeb: isWeb,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter server number';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
          SizedBox(height: isWeb ? 32 : 24),
          
          // Create Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              onPressed: _isCreating ? null : () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isCreating = true);
                  // Your account creation logic here
                }
              },
              child: _isCreating
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: isWeb ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildFormField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  required bool isWeb,
  bool obscureText = false,
  required String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    obscureText: obscureText,
    validator: validator,
    style: TextStyle(
      color: Colors.black,
      fontSize: isWeb ? 16 : 14,
    ),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[700]),
      prefixIcon: Icon(icon, color: Colors.blue[800]),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue[800]!, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red[400]!),
      ),
      contentPadding: EdgeInsets.symmetric(
        vertical: isWeb ? 16 : 14,
        horizontal: 16,
      ),
    ),
  );
}

Future<bool> _checkServerStatus() async {
  return await TripService.checkServerStatus();
}



void _showUserSearch() {
  final isWeb = kIsWeb;
  setState(() {
    _searchQuery = '';
    _foundUsers = [];
    _selectedUser = null;
  });
  
  if (isWeb) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Dialog(
            insetPadding: EdgeInsets.all(20),
            child: _buildUserSearchCard(showCloseButton: true, isWeb: isWeb),
          ),
        ),
      ),
    );
  } else {
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
            child: _buildUserSearchCard(showCloseButton: true, isWeb: isWeb),
          );
        },
      ),
    );
  }
}

Widget _buildUserSearchCard({
  required bool isWeb,
  bool showCloseButton = false,
  bool forWebLayout = false,
  double? webCardHeight,
}) {
  return Card(
    elevation: isWeb ? 4 : 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(isWeb ? 12 : 8),
    ),
    child: Container(
      height: forWebLayout ? webCardHeight ?? 400 : null,
      padding: EdgeInsets.all(isWeb ? 24 : 16),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  forWebLayout ? 'User Search' : 'Find User',
                  style: TextStyle(
                    fontSize: isWeb ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                if (forWebLayout)
                  Icon(Icons.search, color: Colors.blue.shade800),
              ],
            ),
          SizedBox(height: isWeb ? 16 : 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Search by name, email or ID',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: _searchForUsers,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: isWeb ? 16 : 12,
                horizontal: isWeb ? 16 : 12,
              ),
            ),
            onChanged: (value) => _searchQuery = value,
            onSubmitted: (_) => _searchForUsers(),
          ),
          SizedBox(height: isWeb ? 16 : 12),
          if (_isLoadingUsers)
            Center(child: CircularProgressIndicator())
          else if (_foundUsers.isNotEmpty)
            Expanded(
              child: forWebLayout
                  ? ListView.builder(
                      itemCount: _foundUsers.length,
                      itemBuilder: (context, index) {
                        final user = _foundUsers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(user['name'][0]),
                          ),
                          title: Text(user['name']),
                          subtitle: Text(user['email']),
                          onTap: () {
                            _selectUser(user);
                            if (showCloseButton) Navigator.pop(context);
                          },
                          tileColor: index.isEven ? Colors.grey[50] : null,
                        );
                      },
                    )
                  : Column(
                      children: [
                        Text('Search Results', style: TextStyle(fontWeight: FontWeight.bold)),
                        ..._foundUsers.map((user) => ListTile(
                          leading: CircleAvatar(child: Text(user['name'][0])),
                          title: Text(user['name']),
                          subtitle: Text(user['email']),
                          onTap: () {
                            _selectUser(user);
                            if (showCloseButton) Navigator.pop(context);
                          },
                        )).toList(),
                      ],
                    ),
            ),
        ],
      ),
    ),
  );
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

void _showInsuranceSearch() {
  final isWeb = kIsWeb;
  setState(() {
    _searchQuery = '';
    _foundUsers = [];
    _selectedUser = null;
  });

  if (isWeb) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Dialog(
            insetPadding: EdgeInsets.all(20),
            child: _buildInsuranceSearchCard(showCloseButton: true, isWeb: true),
          ),
        ),
      ),
    );
  } else {
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
            child: _buildInsuranceSearchCard(showCloseButton: true, isWeb: false),
          );
        },
      ),
    );
  }
}

Widget _buildInsuranceSearchCard({bool showCloseButton = false, required bool isWeb}) {
  return Container(
    padding: EdgeInsets.all(isWeb ? 24 : 16),
    width: double.infinity,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showCloseButton)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Search Insurance Companies',
                style: TextStyle(
                  fontSize: isWeb ? 20 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        if (!showCloseButton)
          Text(
            'Find Insurance Company',
            style: TextStyle(
              fontSize: isWeb ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
        SizedBox(height: isWeb ? 24 : 16),
        
        // Search Field
        TextField(
          decoration: InputDecoration(
            labelText: 'Search by name, state or ID',
            border: OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(Icons.search),
              onPressed: _searchForInsurance,
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: isWeb ? 16 : 12,
              horizontal: isWeb ? 16 : 12,
            ),
          ),
          style: TextStyle(fontSize: isWeb ? 16 : 14),
          onChanged: (value) => _searchQuery = value,
          onSubmitted: (_) => _searchForInsurance(),
        ),
        SizedBox(height: isWeb ? 24 : 16),
        
        // Search Results
        if (_isLoadingUsers)
          Center(child: CircularProgressIndicator())
        else if (_foundUsers.isNotEmpty)
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(isWeb ? 16 : 12),
              child: Column(
                children: [
                  Text(
                    'Search Results',
                    style: TextStyle(
                      fontSize: isWeb ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  ..._foundUsers.map((user) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.business, color: Colors.blue.shade700),
                    ),
                    title: Text(
                      user['name'],
                      style: TextStyle(fontSize: isWeb ? 16 : 14),
                    ),
                    subtitle: Text(
                      user['state'],
                      style: TextStyle(fontSize: isWeb ? 14 : 12),
                    ),
                    onTap: () {
                      _selectUser(user);
                      if (showCloseButton) Navigator.pop(context);
                    },
                    tileColor: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),
      ],
    ),
  );
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

  void _selectUser(Map<String, dynamic> user) {
  setState(() {
    _selectedUser = user;
    _searchedUserId = user['id'];
  });
  _loadUserScore(user['id']);
  _loadUserTrips(user['id']);
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

Widget _buildAnalyticsCard({required bool isWeb}) {
  return Container(
    constraints: BoxConstraints(
      maxWidth: isWeb ? 800 : double.infinity,
      maxHeight: isWeb ? MediaQuery.of(context).size.height * 0.8 : 
                MediaQuery.of(context).size.height * 0.7,
    ),
    padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analytics Dashboard',
                style: TextStyle(
                  fontSize: isWeb ? 24 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: isWeb ? 24 : 16),
          
          // Platform Usage Section
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(isWeb ? 20 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Platform Usage',
                    style: TextStyle(
                      fontSize: isWeb ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: isWeb ? 250 : 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart, size: 48, color: Colors.blue),
                          SizedBox(height: 16),
                          Text(
                            'Usage analytics will appear here',
                            style: TextStyle(fontSize: isWeb ? 18 : 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isWeb ? 24 : 16),
          
          // Recent Activity Section - Now properly constrained
          Card(
            elevation: 4,
            child: Container(
              padding: EdgeInsets.all(isWeb ? 20 : 16),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: isWeb ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: isWeb ? 300 : 200,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: ClampingScrollPhysics(),
                      itemCount: 10,
                      itemBuilder: (context, index) => Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Icon(Icons.notifications, color: Colors.blue),
                          title: Text(
                            'System notification ${index + 1}',
                            style: TextStyle(fontSize: isWeb ? 16 : 14),
                          ),
                          subtitle: Text(
                            '${index + 5} minutes ago',
                            style: TextStyle(fontSize: isWeb ? 14 : 12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}