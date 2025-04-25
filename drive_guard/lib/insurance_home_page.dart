import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'trip_helper.dart';

class InsuranceHomePage extends StatefulWidget {
  const InsuranceHomePage({Key? key}) : super(key: key);

  @override
  _InsuranceHomePageState createState() => _InsuranceHomePageState();
}

class _InsuranceHomePageState extends State<InsuranceHomePage> {
  String _searchQuery = '';
  List<Map<String, dynamic>> _foundUsers = [];
  Map<String, dynamic>? _selectedUser;
  bool _isLoadingUsers = false;
  bool _isLoadingScore = false;
  bool _isLoadingTrips = false;
  String _tripSortOption = 'recent';
  String _searchedUserId = '';
  List<Map<String, dynamic>> _userTrips = [];
  Map<String, dynamic>? _userScore;
  String _searchError = '';

@override
Widget build(BuildContext context) {
  final isWeb = kIsWeb;

  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(isWeb ? 32.0 : 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1400),
            child: Column(
              children: [
                _buildWelcomeCard(isWeb: isWeb),
                SizedBox(height: isWeb ? 40.0 : 24.0),
                isWeb
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildUserSearchCard(
                                  isWeb: isWeb,
                                  forWebLayout: true,
                                  availableHeight: constraints.maxHeight * 0.4,
                                ),
                                SizedBox(height: 24),
                                _buildUserTripsCard(
                                  isWeb: isWeb,
                                  forWebLayout: true,
                                  availableHeight: constraints.maxHeight * 0.5,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 24),
                          Expanded(
                            flex: 1,
                            child: _buildUserScoreCard(isWeb: isWeb, forWebLayout: true),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildUserSearchCard(isWeb: isWeb),
                          SizedBox(height: 24),
                          _buildUserScoreCard(isWeb: isWeb),
                          SizedBox(height: 24),
                          _buildUserTripsCard(isWeb: isWeb),
                        ],
                      ),
              ],
            ),
          ),
        ),
      );
    },
  );
}


  Widget _buildWelcomeCard({required bool isWeb}) {
    return Card(
      elevation: isWeb ? 8 : 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
      ),
      child: Container(
        padding: EdgeInsets.all(isWeb ? 32 : 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade700, Colors.blue.shade400],
          ),
          borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.dashboard,
              size: isWeb ? 60 : 40,
              color: Colors.white,
            ),
            SizedBox(width: isWeb ? 24 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insurance Dashboard',
                    style: TextStyle(
                      fontSize: isWeb ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: isWeb ? 8 : 4),
                  Text(
                    'Manage user data and driving scores',
                    style: TextStyle(
                      fontSize: isWeb ? 18 : 16,
                      color: Colors.white.withOpacity(0.9),
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

Widget _buildUserSearchCard({
  required bool isWeb,
  bool showCloseButton = false,
  bool forWebLayout = false,
  double? availableHeight,
}) {
  return Card(
    elevation: isWeb ? 4 : 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(isWeb ? 12 : 8),
    ),
    child: Container(
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
            SizedBox(
              height: availableHeight ?? 300,
              child: ListView.builder(
  shrinkWrap: true,
  itemCount: _foundUsers.length,
  itemBuilder: (context, index) {
    final user = _foundUsers[index];
    final name = user['name']?.toString() ?? 'Unknown';
    final email = user['email']?.toString() ?? 'No email';
    final firstChar = name.isNotEmpty ? name[0] : '?';
    
    return ListTile(
      leading: CircleAvatar(child: Text(firstChar)),
      title: Text(name),
      subtitle: Text(email),
      onTap: () {
        _selectUser(user);
        if (showCloseButton) Navigator.pop(context);
      },
    );
  },
),
            )
            else if (_searchError.isNotEmpty)
            Center(child: Text(_searchError, style: TextStyle(color: Colors.red)))
          else
            Center(child: Text('No users found')),
            
        ],
      ),
    ),
  );
}

void _selectUser(Map<String, dynamic> user) {
  setState(() {
    _selectedUser = user;
    _searchedUserId = user['user_id'].toString(); // Convert to String
  });
  _loadUserScore(_searchedUserId);
  _loadUserTrips(_searchedUserId);
}

Widget _buildUserScoreCard({
  required bool isWeb,
  bool forWebLayout = false,
  bool showFullDetails = true,
}) {
  return Card(
    elevation: isWeb ? 4 : 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(isWeb ? 12 : 8),
    ),
    child: Padding(
      padding: EdgeInsets.all(isWeb ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            forWebLayout ? 'Driver Safety Score' : 'User Safety Score',
            style: TextStyle(
              fontSize: isWeb ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: isWeb ? 16 : 12),
          if (_isLoadingScore)
            Center(child: CircularProgressIndicator())
          else if (_userScore == null)
            Center(child: Text('Select a user to view their score'))
          else
            Column(
              children: [
                if (forWebLayout) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _userScore!['score'] / 100,
                        semanticsLabel: 'Safety score',
                        strokeWidth: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getScoreColor(_userScore!['score']),
                        ),
                      ),
                      SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_userScore!['score']}%',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _getScoreRating(_userScore!['score']),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
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
                ],
                SizedBox(height: 16),
                if (showFullDetails && forWebLayout) ...[
                  Divider(),
                  SizedBox(height: 16),
                  _buildScoreDetailRow('Acceleration', 85),
                  _buildScoreDetailRow('Braking', 72),
                  _buildScoreDetailRow('Cornering', 91),
                  _buildScoreDetailRow('Speed Compliance', 88),
                ],
                SizedBox(height: 8),
                Text(
                  'Last updated: ${TripService.formatTimestamp(_userScore!['updated_at'])}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: isWeb ? 14 : 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

Widget _buildScoreDetailRow(String label, int value) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label),
        ),
        Expanded(
          flex: 3,
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(value)),
          ),
        ),
        SizedBox(width: 8),
        Text(
          '$value%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getScoreColor(value),
          ),
        ),
      ],
    ),
  );
}

Color _getScoreColor(int score) {
  if (score >= 85) return Colors.green;
  if (score >= 70) return Colors.blue[700]!;
  if (score >= 50) return Colors.orange;
  return Colors.red;
}

String _getScoreRating(int score) {
  if (score >= 85) return 'Excellent';
  if (score >= 70) return 'Good';
  if (score >= 50) return 'Fair';
  return 'Needs Improvement';
}

Widget _buildUserTripsCard({
  required bool isWeb,
  bool forWebLayout = false,
  bool showSortControls = true,
  double? availableHeight,
}) {
  return Card(
    elevation: isWeb ? 4 : 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(isWeb ? 12 : 8),
    ),
    child: Container(
      padding: EdgeInsets.all(isWeb ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Trips',
                style: TextStyle(
                  fontSize: isWeb ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              if (showSortControls && (isWeb || forWebLayout))
                DropdownButton<String>(
                  value: _tripSortOption,
                  items: [
                    DropdownMenuItem(
                      value: 'recent',
                      child: Text('Most Recent'),
                    ),
                    DropdownMenuItem(
                      value: 'distance',
                      child: Text('Longest Distance'),
                    ),
                  ],
                  onChanged: (value) => _setTripSort(value!),
                ),
            ],
          ),
          SizedBox(height: isWeb ? 16 : 12),
          SizedBox(
            height: availableHeight ?? 300, // Dynamically provided or fallback
            child: _isLoadingTrips
                ? Center(child: CircularProgressIndicator())
                : _userTrips.isEmpty
                    ? Center(
                        child: Text(
                          _selectedUser == null
                              ? 'Select a user to view trips'
                              : 'No trips found',
                        ),
                      )
                    : ListView.separated(
                        itemCount: _userTrips.length,
                        separatorBuilder: (context, index) => Divider(),
                        itemBuilder: (context, index) {
                          final trip = _userTrips[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            leading: Icon(
                              Icons.directions_car,
                              color: Colors.blue.shade800,
                            ),
                            title: Text(
                              TripService.formatTimestamp(trip['start_time']),
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              '${trip['distance'].toStringAsFixed(2)} miles',
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.info_outline),
                              onPressed: () =>
                                  TripService.showTripDetails(context, trip),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    ),
  );
}


void _setTripSort(String sortOption) {
  setState(() {
    _tripSortOption = sortOption;
  });
  if (_searchedUserId.isNotEmpty) {
    _loadUserTrips(_searchedUserId);
  }
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
    _searchError = '';
  });

  try {
    final results = await TripService.searchUsers(_searchQuery);
    print('API results: $results');
    
    setState(() {
      _foundUsers = results.map((user) {
        return {
          'id': user['user_id'],
          'name': '${user['first_name']} ${user['last_name']}',
          'email': user['email'],
          'role': user['role'],
        };
      }).toList();
      _isLoadingUsers = false;
    });
  } catch (e) {
    print('Search error: $e');
    setState(() {
      _isLoadingUsers = false;
      _searchError = 'Search failed: ${e.toString()}';
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
}