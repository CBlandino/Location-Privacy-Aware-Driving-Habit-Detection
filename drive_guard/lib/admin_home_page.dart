import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'ipconfig.dart';
import 'trip_helper.dart';

// AdminHomePage is the main dashboard for administrators, providing:
// - System statistics overview
// - User and insurance company management
// - Server status monitoring
// - Account creation functionality
// Responsively designed for both web and mobile platforms
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  // STATE MANAGEMENT SECTION
  
  // Quick Stats State - Tracks system-wide statistics
  Map<String, dynamic> _quickStats = {
    'total_users': 0,
    'total_admins': 0,
    'total_insurance': 0,
  };
  bool _isLoadingStats = false;
  String _statsError = '';

  // Server Information State - Stores server configuration details
  Map<String, dynamic>? _serverInfo;
  bool _isLoadingServerInfo = false;
  String _serverInfoError = '';

  // Insurance Search State - Manages insurance company search functionality
  List<Map<String, dynamic>> _insuranceResults = [];
  bool _isLoadingInsurance = false;
  String _insuranceSearchError = '';
  String _insuranceSearchQuery = '';

  // User Search State - Manages user search functionality
  List<Map<String, dynamic>> _userResults = [];
  bool _isLoadingUsers = false;
  String _userSearchError = '';
  String _userSearchQuery = '';

  // Account Creation State - Manages form state for new account creation
  final _createAccountFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _adminIdController = TextEditingController();
  final _serverNumberController = TextEditingController();

  String _selectedRole = 'user'; // Default role selection
  bool _isCreatingAccount = false;
  String _createAccountError = '';

  // Web-specific hover states for interactive elements
  bool _isHoveringCreateAccount = false;
  bool _isHoveringSearchUsers = false;
  bool _isHoveringSearchInsurance = false;
  bool _isHoveringAnalytics = false;

  // LIFECYCLE METHODS

  @override
  void initState() {
    super.initState();
    // Load initial data when widget is created
    _fetchQuickStats();
    _fetchServerInfo();
  }

  @override
  void dispose() {
    // Clean up all controllers to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _adminIdController.dispose();
    _serverNumberController.dispose();
    super.dispose();
  }

  // MAIN BUILD METHOD

  @override
  Widget build(BuildContext context) {
    // Responsive layout calculations
    final isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 800;

    return Scaffold(
      // Web-specific app bar
      appBar: isWeb ? _buildWebAppBar() : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(isWeb ? 24 : 12),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 1400,
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mobile-only welcome card
                    if (!isWeb) _buildWelcomeCard(isWeb: isWeb),
                    SizedBox(height: isLargeScreen ? 32 : 16),
                    // Quick stats display
                    _buildQuickStatsRow(),
                    SizedBox(height: isLargeScreen ? 32 : 16),
                    // Platform-specific dashboard layout
                    if (isWeb)
                      _buildWebDashboard(isLargeScreen, isMediumScreen)
                    else
                      _buildMobileDashboard(),
                    SizedBox(height: isLargeScreen ? 32 : 16),
                    // Server status information
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

  // WEB-SPECIFIC COMPONENTS SECTION

  // Builds the web-specific app bar with admin controls
  AppBar _buildWebAppBar() {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.admin_panel_settings, size: 32),
          SizedBox(width: 12),
          Text('Admin Dashboard', style: TextStyle(fontSize: 24)),
        ],
      ),
      elevation: 4,
      actions: [
        // Refresh data button
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: () {
            _fetchQuickStats();
            _fetchServerInfo();
          },
          tooltip: 'Refresh Data',
        ),
        // Logout button
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: _logout,
          tooltip: 'Logout',
        ),
      ],
    );
  }

  // Builds the web dashboard layout with responsive grid
  Widget _buildWebDashboard(bool isLargeScreen, bool isMediumScreen) {
    final cardSpacing = isLargeScreen ? 24.0 : 16.0;
    final cardHeight = isLargeScreen ? 220.0 : 180.0;

    return Column(
      children: [
        // Action cards grid
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: isLargeScreen ? 4 : (isMediumScreen ? 2 : 1),
          childAspectRatio: isLargeScreen ? 1.2 : 1.5,
          crossAxisSpacing: cardSpacing,
          mainAxisSpacing: cardSpacing,
          padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 24 : 0),
          children: [
            _buildAdminActionCard(
              icon: Icons.person_add,
              title: 'Create Account',
              description: 'Register new users, admins, or insurance companies',
              color: Colors.blue,
              onTap: () => _showCreateAccountModal(),
              isWeb: true,
              isHovering: _isHoveringCreateAccount,
              onHover: (hovering) => setState(() => _isHoveringCreateAccount = hovering),
              height: cardHeight,
            ),
            _buildAdminActionCard(
              icon: Icons.search,
              title: 'Search Users',
              description: 'Find and manage user accounts',
              color: Colors.green,
              onTap: () => _showUserSearch(),
              isWeb: true,
              isHovering: _isHoveringSearchUsers,
              onHover: (hovering) => setState(() => _isHoveringSearchUsers = hovering),
              height: cardHeight,
            ),
            _buildAdminActionCard(
              icon: Icons.business,
              title: 'Search Insurance',
              description: 'Manage insurance company accounts',
              color: Colors.orange,
              onTap: () => _showInsuranceSearch(),
              isWeb: true,
              isHovering: _isHoveringSearchInsurance,
              onHover: (hovering) => setState(() => _isHoveringSearchInsurance = hovering),
              height: cardHeight,
            ),
            _buildAdminActionCard(
              icon: Icons.analytics,
              title: 'View Analytics',
              description: 'System usage and activity reports',
              color: Colors.purple,
              onTap: () => _showAnalytics(),
              isWeb: true,
              isHovering: _isHoveringAnalytics,
              onHover: (hovering) => setState(() => _isHoveringAnalytics = hovering),
              height: cardHeight,
            ),
          ],
        ),
        // Additional data grid for large screens
        if (isLargeScreen) SizedBox(height: 32),
        if (isLargeScreen) _buildWebDataGrid(),
      ],
    );
  }

  // Builds the detailed data grid for web view
  Widget _buildWebDataGrid() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: Row(
                children: [
                  // Recent activity panel
                  Expanded(
                    flex: 2,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Activity',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: 10,
                                itemBuilder: (context, index) => ListTile(
                                  leading: Icon(Icons.notification_important, size: 20),
                                  title: Text('System update ${index + 1}'),
                                  subtitle: Text('${index + 5} minutes ago'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // User distribution panel
                  Expanded(
                    flex: 3,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User Distribution',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Expanded(
                              child: Center(
                                child: Icon(
                                  Icons.pie_chart,
                                  size: 100,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  // MOBILE COMPONENTS SECTION

  // Builds the mobile-optimized dashboard layout
  Widget _buildMobileDashboard() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      padding: EdgeInsets.symmetric(horizontal: 8),
      children: _buildActionCards(),
    );
  }

  // Generates action cards for mobile view
  List<Widget> _buildActionCards() {
    return [
      _buildAdminActionCard(
        icon: Icons.person_add,
        title: 'Create Account',
        description: 'Register new users',
        color: Colors.blue,
        onTap: () => _showCreateAccountModal(),
        isWeb: false,
      ),
      _buildAdminActionCard(
        icon: Icons.search,
        title: 'Search Users',
        description: 'Find user accounts',
        color: Colors.green,
        onTap: () => _showUserSearch(),
        isWeb: false,
      ),
      _buildAdminActionCard(
        icon: Icons.business,
        title: 'Search Insurance',
        description: 'Manage companies',
        color: Colors.orange,
        onTap: () => _showInsuranceSearch(),
        isWeb: false,
      ),
      _buildAdminActionCard(
        icon: Icons.analytics,
        title: 'Analytics',
        description: 'View reports',
        color: Colors.purple,
        onTap: () => _showAnalytics(),
        isWeb: false,
      ),
    ];
  }

  // SHARED COMPONENTS SECTION

  // Builds a reusable admin action card component
  Widget _buildAdminActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    required bool isWeb,
    bool isHovering = false,
    Function(bool)? onHover,
    double? height,
  }) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    return MouseRegion(
      onEnter: onHover != null ? (_) => onHover(true) : null,
      onExit: onHover != null ? (_) => onHover(false) : null,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: isWeb ? (isHovering ? 8 : 4) : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isWeb && isHovering ? color.withOpacity(0.05) : Colors.white,
              border: isWeb && isHovering
                  ? Border.all(color: color.withOpacity(0.3), width: 1)
                  : null,
            ),
            padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(height: 12),
                // Title text
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isLargeScreen ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                // Description text
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isLargeScreen ? 14 : 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Web-specific forward arrow indicator
                if (isWeb) ...[
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      Icons.arrow_forward,
                      color: isHovering ? color : Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // DATA DISPLAY COMPONENTS SECTION

  // Builds the quick stats row showing system metrics
  Widget _buildQuickStatsRow() {
    if (_isLoadingStats) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_statsError.isNotEmpty) {
      return Card(
        child: Padding(padding: EdgeInsets.all(24), child: Text(_statsError)),
      );
    }

    final isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1000;
    final maxStatWidth = isWeb ? 1200.0 : 800.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxStatWidth),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: 24,
              horizontal: isLargeScreen ? 40 : 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  Icons.people,
                  'Total Users',
                  _quickStats['total_users'].toString(),
                  Colors.blue,
                  isLargeScreen,
                ),
                _buildStatItem(
                  Icons.admin_panel_settings,
                  'Total Admins',
                  _quickStats['total_admins'].toString(),
                  Colors.green,
                  isLargeScreen,
                ),
                _buildStatItem(
                  Icons.business,
                  'Insurance Cos',
                  _quickStats['total_insurance'].toString(),
                  Colors.orange,
                  isLargeScreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Builds the server status information card
  Widget _buildServerStatusCard({required bool isWeb}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Server Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 16),
            if (_isLoadingServerInfo)
              Center(child: CircularProgressIndicator())
            else if (_serverInfoError.isNotEmpty)
              Center(child: Text(_serverInfoError))
            else if (_serverInfo != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServerInfoItem('Base URL', _serverInfo!['base_url']),
                  _buildServerInfoItem('Port', _serverInfo!['port']),
                  _buildServerInfoItem('API Key', '••••••••••••••••'),
                ],
              ),
            SizedBox(height: 16),
            // Server status indicator
            FutureBuilder<bool>(
              future: _checkServerStatus(),
              builder: (context, snapshot) {
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

  // Builds the welcome card for mobile view
  Widget _buildWelcomeCard({required bool isWeb}) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: double.infinity),
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

  // UTILITY COMPONENTS SECTION

  // Builds a server info display row
  Widget _buildServerInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // Builds a statistic display item with icon
  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
    bool isLarge,
  ) {
    final iconSize = isLarge ? 36.0 : 28.0;
    final numberSize = isLarge ? 28.0 : 22.0;
    final labelSize = isLarge ? 16.0 : 14.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon container
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
        SizedBox(height: 12),
        // Value display
        Text(
          value,
          style: TextStyle(fontSize: numberSize, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        // Label display
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: labelSize),
        ),
      ],
    );
  }

  // MODAL DIALOGS SECTION

  // Shows the account creation modal (platform-specific)
  void _showCreateAccountModal() {
    final isWeb = kIsWeb;

    if (isWeb) {
      showDialog(
        context: context,
        builder: (context) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Dialog(
              insetPadding: EdgeInsets.all(20),
              child: _buildCreateAccountForm(),
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
                child: _buildCreateAccountForm(),
              );
            },
          ),
        ),
      );
    }
  }

  // Builds the account creation form with role-specific fields
  Widget _buildCreateAccountForm() {
    final isWeb = kIsWeb;
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
      ),
      padding: EdgeInsets.all(isWeb ? 24 : 16),
      child: Form(
        key: _createAccountFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create New Account',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 22 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Role selection dropdown
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 93, 175, 233),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Account Type',
                  labelStyle: TextStyle(color: Colors.blue[800], fontSize: 14),
                ),
                style: TextStyle(fontSize: 14),
                dropdownColor: const Color.fromARGB(255, 93, 175, 233),
                icon: Icon(Icons.arrow_drop_down, color: Colors.blue[800]),
                items: [
                  DropdownMenuItem(value: 'user', child: Text('User Account')),
                  DropdownMenuItem(
                    value: 'insurance',
                    child: Text('Insurance Company'),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Admin Account'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                    // Clear form fields when role changes
                    _firstNameController.clear();
                    _lastNameController.clear();
                    _adminIdController.clear();
                    _serverNumberController.clear();
                  });
                },
              ),
            ),
            SizedBox(height: 16),

            // Dynamic form fields based on selected role
            Column(
              children: [
                // Common fields (email and password)
                _buildFormField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
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
                SizedBox(height: 12),

                _buildFormField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock,
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
                SizedBox(height: 12),

                // Role-specific fields
                if (_selectedRole == 'user') ...[
                  _buildFormField(
                    controller: _firstNameController,
                    label: 'First Name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter first name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  _buildFormField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    icon: Icons.person_outline,
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter company name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  _buildFormField(
                    controller: _lastNameController,
                    label: 'State',
                    icon: Icons.location_on,
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
                    controller: _firstNameController,
                    label: 'First Name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter first name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  _buildFormField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter last name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  _buildFormField(
                    controller: _adminIdController,
                    label: 'Admin ID',
                    icon: Icons.admin_panel_settings,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter admin ID';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  _buildFormField(
                    controller: _serverNumberController,
                    label: 'Server Number',
                    icon: Icons.computer,
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
            SizedBox(height: 16),

            // Error message display
            if (_createAccountError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  _createAccountError,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isCreatingAccount ? null : _createAccount,
                child: _isCreatingAccount
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 14,
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

  // Builds a reusable form field with consistent styling
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    required String? Function(String?)? validator,
  }) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(color: Colors.black, fontSize: isLargeScreen ? 16 : 14),
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
          vertical: isLargeScreen ? 16 : 14,
          horizontal: 16,
        ),
      ),
    );
  }

  // Shows the user search modal (platform-specific)
  void _showUserSearch() {
    final isWeb = kIsWeb;

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
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return _buildUserSearchForm(setModalState);
                },
              ),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.8,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: _buildUserSearchForm(setModalState),
                  );
                },
              );
            },
          );
        },
      );
    }
  }

  // Shows detailed user information dialog
  void _showUserDetailsDialog(Map<String, dynamic> user) {
    final isWeb = kIsWeb;
    final maxDialogWidth = isWeb ? 500.0 : double.infinity;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxDialogWidth),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User header with avatar
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blue[100],
                      child: Icon(
                        Icons.person,
                        color: Colors.blue[700],
                        size: 30,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 8),
                // User details rows
                _buildUserDetailRow('Email', user['email']),
                _buildUserDetailRow('Role', user['role']),
                _buildUserDetailRow('User ID', user['user_id']),
                if (user.containsKey('policy_number'))
                  _buildUserDetailRow('Policy Number', user['policy_number']),
                SizedBox(height: 20),
                // Close button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.check),
                    label: Text('Close'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Builds a user detail row for the details dialog
  Widget _buildUserDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Builds the user search form with results display
  Widget _buildUserSearchForm([void Function(VoidCallback fn)? setModalState]) {
    final isWeb = kIsWeb;
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isWeb ? 16 : 12),
            topRight: Radius.circular(isWeb ? 16 : 12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search Users',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Search input
            TextField(
              decoration: InputDecoration(
                labelText: 'Search by name, email or ID',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _searchUsers(setModalState, context),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
              ),
              onChanged: (value) => _userSearchQuery = value,
              onSubmitted: (value) {
                _userSearchQuery = value;
                if (setModalState != null) {
                  _searchUsers(setModalState);
                } else {
                  _searchUsers();
                }
              },
            ),
            SizedBox(height: 16),
            // Results display
            Builder(
              builder: (context) {
                if (_isLoadingUsers) {
                  return Center(child: CircularProgressIndicator());
                } else if (_userSearchError.isNotEmpty) {
                  return Text(
                    _userSearchError,
                    style: TextStyle(color: Colors.red),
                  );
                } else if (_userResults.isEmpty && _userSearchQuery.isNotEmpty) {
                  return Text('No users found matching "$_userSearchQuery".');
                } else {
                  return _buildUserList();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Builds the list of user search results
  Widget _buildUserList() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _userResults.length,
        separatorBuilder: (_, __) => SizedBox(height: 8),
        itemBuilder: (context, index) {
          final user = _userResults[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.green[100],
                child: Icon(Icons.person, color: Colors.green[800]),
              ),
              title: Text(
                '${user['first_name']} ${user['last_name']}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(
                    user['email'],
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Text(
                    'Role: ${user['role'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              trailing: Icon(Icons.chevron_right),
              onTap: () => _showUserDetailsDialog(user),
            ),
          );
        },
      ),
    );
  }

  // Shows the insurance search modal (platform-specific)
  void _showInsuranceSearch() {
    final isWeb = kIsWeb;

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
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return _buildInsuranceSearchForm(setModalState);
                },
              ),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.8,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: _buildInsuranceSearchForm(setModalState),
                  );
                },
              );
            },
          );
        },
      );
    }
  }

  // Builds the insurance search form with results display
  Widget _buildInsuranceSearchForm([
    void Function(VoidCallback fn)? setModalState,
  ]) {
    final isWeb = kIsWeb;
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isWeb ? 16 : 12),
            topRight: Radius.circular(isWeb ? 16 : 12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search Insurance Users',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Search input
            TextField(
              decoration: InputDecoration(
                labelText: 'Search by policy number or insurance company',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _searchInsurance(setModalState, context),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
              ),
              onChanged: (value) => _insuranceSearchQuery = value,
              onSubmitted: (value) {
                _insuranceSearchQuery = value;
                _searchInsurance(setModalState, context);
              },
            ),
            SizedBox(height: 16),
            // Results display
            Builder(
              builder: (context) {
                if (_isLoadingInsurance) {
                  return Center(child: CircularProgressIndicator());
                } else if (_insuranceSearchError.isNotEmpty) {
                  return Text(
                    _insuranceSearchError,
                    style: TextStyle(color: Colors.red),
                  );
                } else if (_insuranceResults.isEmpty &&
                    _insuranceSearchQuery.isNotEmpty) {
                  return Text('No users found for "$_insuranceSearchQuery".');
                } else {
                  return _buildInsuranceUserList();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Builds the list of insurance search results
  Widget _buildInsuranceUserList() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _insuranceResults.length,
        separatorBuilder: (_, __) => SizedBox(height: 8),
        itemBuilder: (context, index) {
          final user = _insuranceResults[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.orange[100],
                child: Icon(Icons.business, color: Colors.orange[800]),
              ),
              title: Text(
                '${user['first_name']} ${user['last_name']}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(
                    user['email'],
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Text(
                    'Role: ${user['role'] ?? 'insurance'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              trailing: Icon(Icons.chevron_right),
              onTap: () => _showUserDetailsDialog(user),
            ),
          );
        },
      ),
    );
  }

  // Shows the analytics modal (platform-specific)
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
              child: _buildAnalyticsDashboard(),
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
              child: _buildAnalyticsDashboard(),
            );
          },
        ),
      );
    }
  }

  // Builds the analytics dashboard content
  Widget _buildAnalyticsDashboard() {
    final isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1000;

    return Container(
      padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isWeb ? 16 : 12),
          topRight: Radius.circular(isWeb ? 16 : 12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'System Analytics',
                style: TextStyle(
                  fontSize: isLargeScreen ? 24 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: isLargeScreen ? 24 : 16),
          // User statistics card
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Statistics',
                    style: TextStyle(
                      fontSize: isLargeScreen ? 20 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          Icons.people,
                          'Total Users',
                          _quickStats['total_users'].toString(),
                          Colors.blue,
                          isLargeScreen,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          Icons.admin_panel_settings,
                          'Admins',
                          _quickStats['total_admins'].toString(),
                          Colors.green,
                          isLargeScreen,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          Icons.business,
                          'Insurance',
                          _quickStats['total_insurance'].toString(),
                          Colors.orange,
                          isLargeScreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isLargeScreen ? 24 : 16),
          // Activity overview card
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity Overview',
                    style: TextStyle(
                      fontSize: isLargeScreen ? 20 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 200,
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
                            'Activity charts will appear here',
                            style: TextStyle(fontSize: isLargeScreen ? 18 : 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isLargeScreen ? 24 : 16),
          if (isWeb) SizedBox(height: 24),
        ],
      ),
    );
  }

  // DATA METHODS SECTION

  // Fetches quick stats from the server
  Future<void> _fetchQuickStats() async {
    setState(() {
      _isLoadingStats = true;
      _statsError = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.server}/admin/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _quickStats = {
            'total_users': data['total_users'] ?? 0,
            'total_admins': data['total_admins'] ?? 0,
            'total_insurance': data['total_insurance'] ?? 0,
          };
        });
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _statsError = 'Failed to load stats: $e';
      });
    } finally {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  // Fetches server information
  Future<void> _fetchServerInfo() async {
    setState(() {
      _isLoadingServerInfo = true;
      _serverInfoError = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.server}/server-info'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _serverInfo = jsonDecode(response.body);
        });
      } else {
        //throw Exception('Failed to load server info: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        // _serverInfoError = 'Failed to load server info: $e';
      });
    } finally {
      setState(() {
        _isLoadingServerInfo = false;
      });
    }
  }

  // Searches for users based on query
  void _searchUsers([
    void Function(VoidCallback fn)? modalSetState,
    BuildContext? context,
  ]) async {
    if (context != null) FocusScope.of(context).unfocus();
    final setStateFn = modalSetState ?? setState;

    setStateFn(() {
      _isLoadingUsers = true;
      _userSearchError = '';
      _userResults = [];
    });

    try {
      final results = await TripService.searchUsers(_userSearchQuery);
      setStateFn(() {
        _userResults = results;
      });
    } catch (e) {
      setStateFn(() {
        _userSearchError = e.toString();
      });
    } finally {
      setStateFn(() {
        _isLoadingUsers = false;
      });
    }
  }

  // Searches for insurance users based on query
  Future<void> _searchInsurance([
    void Function(VoidCallback fn)? modalSetState,
    BuildContext? context,
  ]) async {
    if (context != null) FocusScope.of(context).unfocus();

    final setStateFn = modalSetState ?? setState;

    setStateFn(() {
      _isLoadingInsurance = true;
      _insuranceSearchError = '';
      _insuranceResults = [];
    });

    try {
      final results = await TripService.searchUsers(_insuranceSearchQuery);
      setStateFn(() {
        _insuranceResults = results;
      });
    } catch (e) {
      setStateFn(() {
        _insuranceSearchError = e.toString();
      });
    } finally {
      setStateFn(() {
        _isLoadingInsurance = false;
      });
    }
  }

  // Creates a new account with form data
  Future<void> _createAccount() async {
    if (!_createAccountFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreatingAccount = true;
      _createAccountError = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      Map<String, dynamic> requestBody = {
        'email': _emailController.text,
        'password': _passwordController.text,
        'role': _selectedRole,
      };

      // Add role-specific fields
      if (_selectedRole == 'user') {
        requestBody['first_name'] = _firstNameController.text;
        requestBody['last_name'] = _lastNameController.text;
      } else if (_selectedRole == 'insurance') {
        requestBody['company_name'] = _firstNameController.text;
        requestBody['state'] = _lastNameController.text;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.server}/create-account'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _clearCreateAccountForm();
      } else {
        throw Exception('Failed to create account: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _createAccountError = 'Failed to create account: $e';
      });
    } finally {
      setState(() {
        _isCreatingAccount = false;
      });
    }
  }

  // Clears the account creation form
  void _clearCreateAccountForm() {
    _emailController.clear();
    _passwordController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    setState(() {
      _selectedRole = 'user';
    });
  }

  // Checks if the server is online
  Future<bool> _checkServerStatus() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.server}/ping'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Logs out the current admin user
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    Navigator.pushReplacementNamed(context, '/login');
  }
}