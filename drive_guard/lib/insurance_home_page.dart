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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(isWeb: isWeb),
                SizedBox(height: isWeb ? 32 : 24),
                Text('Manage Users', style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 12),
                isWeb ? _buildWebLayout(constraints) : _buildMobileLayout(isWeb),
              ],
            ),
          ),
        ),
      );
    },
  );
}


Widget _buildWebLayout(BoxConstraints constraints) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 2,
        child: Column(
          children: [
            _buildUserSearchCard(isWeb: true, forWebLayout: true, availableHeight: constraints.maxHeight * 0.4),
            SizedBox(height: 24),
            _buildUserTripsCard(isWeb: true, forWebLayout: true, availableHeight: constraints.maxHeight * 0.5),
          ],
        ),
      ),
      SizedBox(width: 24),
      Expanded(
        flex: 1,
        child: _buildUserScoreCard(isWeb: true, forWebLayout: true),
      ),
    ],
  );
}

Widget _buildMobileLayout(bool isWeb) {
  return Column(
    children: [
      _buildUserSearchCard(isWeb: isWeb),
      SizedBox(height: 24),
      _buildUserScoreCard(isWeb: isWeb),
      SizedBox(height: 24),
      _buildUserTripsCard(isWeb: isWeb),
    ],
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
                      color: Colors.white.withAlpha(230),
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
  final effectiveHeight = availableHeight ?? (isWeb ? 400.0 : 300.0);

  return Card(
    elevation: isWeb ? 4 : 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(isWeb ? 12 : 8),
    ),
    child: Container(
      padding: EdgeInsets.all(isWeb ? 16 : 12),
      constraints: BoxConstraints(
        minHeight: 200,
        maxHeight: effectiveHeight,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
           SizedBox(height: isWeb ? 12 : 8),
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
          SizedBox(height: isWeb ? 12 : 8),
          
          if (_isLoadingUsers)
            Container(
              height: effectiveHeight * 0.5,
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
          else if (_foundUsers.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 100,
                maxHeight: effectiveHeight - 100, // Account for header space
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: _foundUsers.length,
                itemBuilder: (context, index) {
                  final user = _foundUsers[index];
                  final name = user['name']?.toString() ?? 'Unknown';
                  final email = user['email']?.toString() ?? 'No email';
                  final firstChar = name.isNotEmpty ? name[0] : '?';

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
            dense: true,
  visualDensity: VisualDensity.compact,
  contentPadding: EdgeInsets.symmetric(horizontal: isWeb ? 8 : 4),
                      leading: CircleAvatar(
                        radius: isWeb ? 20 : 16,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          firstChar,
                          style: TextStyle(color: Colors.blue.shade800),
                        ),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontSize: isWeb ? 14 : 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        email,
                        style: TextStyle(fontSize: isWeb ? 12 : 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        if (user['user_id'] != null) {
                          _selectUser(user);
                          if (showCloseButton) Navigator.pop(context);
                        }
                      },
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: effectiveHeight * 0.5,
              alignment: Alignment.center,
              child: Text(
                _searchError.isNotEmpty 
                    ? _searchError
                    : 'No users found',
                style: TextStyle(
                  color: _searchError.isNotEmpty ? Colors.red : Colors.grey,
                ),
              ),
            ),
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
  // Convert score from 0-1 to 0-100 if needed
  final score = _userScore != null 
      ? (_userScore!['score'] is double && _userScore!['score'] <= 1.0 
          ? (_userScore!['score'] * 100).round() 
          : _userScore!['score'].round())
      : 0;

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
                // Mobile-friendly score display
                if (!isWeb && !forWebLayout) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: score / 100,
                                  semanticsLabel: 'Safety score',
                                  strokeWidth: 8,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getScoreColor(score.toDouble()),
                                  ),
                                ),
                                Text(
                                  '$score',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _getScoreRating(score.toDouble()),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_userScore!.containsKey('accel_score'))
                              _buildMobileScoreRow(
                                'Acceleration', 
                                (_userScore!['accel_score'] * 100).round(),
                              ),
                            if (_userScore!.containsKey('brake_score'))
                              _buildMobileScoreRow(
                                'Braking', 
                                (_userScore!['brake_score'] * 100).round(),
                              ),
                            if (_userScore!.containsKey('trip_score'))
                              _buildMobileScoreRow(
                                'Overall', 
                                (_userScore!['trip_score'] * 100).round(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Web layout
                  if (forWebLayout) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: score / 100,
                          semanticsLabel: 'Safety score',
                          strokeWidth: 10,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getScoreColor(score.toDouble()),
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$score%',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _getScoreRating(score.toDouble()),
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
                      value: score / 100,
                      semanticsLabel: 'Safety score',
                    ),
                    SizedBox(height: 16),
                    Text(
                      '$score%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
                
                // Additional details for web layout
                if (showFullDetails && forWebLayout) ...[
                  Divider(),
                  SizedBox(height: 16),
                  if (_userScore!.containsKey('accel_score'))
                    _buildScoreDetailRow(
                      'Acceleration', 
                      (_userScore!['accel_score'] * 100).round()
                    ),
                  if (_userScore!.containsKey('brake_score'))
                    _buildScoreDetailRow(
                      'Braking', 
                      (_userScore!['brake_score'] * 100).round()
                    ),
                  if (_userScore!.containsKey('trip_score'))
                    _buildScoreDetailRow(
                      'Overall Score', 
                      (_userScore!['trip_score'] * 100).round()
                    ),
                ],
                
                // Calculation details section - added here
                if (_userScore != null && _userScore!['calculation'] != null)
                  _buildCalculationDetails(context, _userScore!),
                
                SizedBox(height: 8),
                if (_userScore!.containsKey('updated_at'))
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

Widget _buildCalculationDetails(BuildContext context, Map<String, dynamic> scoreData) {
final calculation = scoreData['calculation'] as Map<String, dynamic>? ?? {};
final allTrips = scoreData['all_trips'] as List<dynamic>? ?? [];
final hasTrips = allTrips.isNotEmpty;

return ExpansionTile(
title: Text(
'Score Calculation Details',
style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
),
initiallyExpanded: false,
childrenPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
children: [
if (calculation['formula'] != null)
Padding(
padding: EdgeInsets.only(bottom: 12),
child: Text(
calculation['formula'],
style: TextStyle(fontStyle: FontStyle.italic),
),
),
if (calculation['weights'] != null) ...[
Text('Weight Distribution:', style: TextStyle(fontWeight: FontWeight.w500)),
SizedBox(height: 8),
...(calculation['weights'] as Map<String, dynamic>).entries.map((e) =>
Padding(
padding: EdgeInsets.symmetric(vertical: 4),
child: Row(
children: [
Expanded(flex: 2, child: Text(e.key.replaceAll('_', ' ').toUpperCase())),
Expanded(
flex: 3,
child: LinearProgressIndicator(
value: e.value.toDouble(),
backgroundColor: Colors.grey[200],
valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
),
),
SizedBox(width: 8),
Text('${(e.value.toDouble() * 100).round()}%'),
],
),
),
),
],
SizedBox(height: 12),
if (hasTrips) ...[
Text('Trip Data Summary (${allTrips.length} trips):', style: TextStyle(fontWeight: FontWeight.w500)),
SizedBox(height: 8),
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
_buildTripStat('Total Distance',
'${allTrips.fold(0.0, (sum, trip) => sum + (trip['distance'] ?? 0.0)).toStringAsFixed(1)} miles'),
_buildTripStat('Avg. Score',
(allTrips.fold(0.0, (sum, trip) => sum + (trip['trip_score'] ?? 0.0)) / allTrips.length).toStringAsFixed(1)),
],
),
SizedBox(height: 8),
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
_buildTripStat('Avg. Braking',
(allTrips.fold(0.0, (sum, trip) => sum + (trip['brake_score'] ?? 0.0)) / allTrips.length).toStringAsFixed(1)),
_buildTripStat('Avg. Acceleration',
(allTrips.fold(0.0, (sum, trip) => sum + (trip['accel_score'] ?? 0.0)) / allTrips.length).toStringAsFixed(1)),
],
),
SizedBox(height: 16),
Text('User Trips:', style: TextStyle(fontWeight: FontWeight.w500)),
SizedBox(height: 8),
...allTrips.take(3).map((trip) => _buildTripMetricCard(trip)),
if (allTrips.length > 3)
Text('+ ${allTrips.length - 3} more trips...', style: TextStyle(color: Colors.grey)),
] else
Text('No trip data available for this user', style: TextStyle(color: Colors.grey)),
],
);
}

Widget _buildTripStat(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _buildTripMetricCard(Map<String, dynamic> trip) {
  return ExpansionTile(
    title: Text('Trip ID ${trip['trip_id']}'),
    subtitle: Text(TripService.formatTimestamp(trip['start_time'])),
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildTripMetricItem('Distance', '${trip['distance']?.toStringAsFixed(1) ?? 'N/A'} miles')),
                Expanded(child: _buildTripMetricItem('Duration', '${trip['duration']?.toStringAsFixed(1) ?? 'N/A'} min')),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: _buildTripMetricItem('Avg Speed', '${trip['avg_speed']?.toStringAsFixed(1) ?? 'N/A'} mph')),
                Expanded(child: _buildTripMetricItem('Max Speed', '${trip['max_speed']?.toStringAsFixed(1) ?? 'N/A'} mph')),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: _buildTripMetricItem('Score', '${trip['trip_score']?.toStringAsFixed(1) ?? 'N/A'}')),
                Expanded(child: _buildTripMetricItem('Date', TripService.formatTimestamp(trip['start_time'], dateOnly: true))),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}


Widget _buildTripMetricItem(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
      Text(value, style: TextStyle(fontSize: 14)),
    ],
  );
}

Widget _buildMobileScoreRow(String label, int score) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 5, // wider bar for progress
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getScoreColor(score.toDouble()),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '$score%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(score.toDouble()),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


Widget _buildScoreDetailRow(String label, double value) {
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
            value: value,
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

Color _getScoreColor(double score) {
  if (score >= 85) return Colors.green;
  if (score >= 70) return Colors.blue[700]!;
  if (score >= 50) return Colors.orange;
  return Colors.red;
}

String _getScoreRating(double score) {
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
final effectiveHeight = availableHeight ?? (isWeb ? 400.0 : 300.0);

return Card(
elevation: isWeb ? 4 : 2,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(isWeb ? 12 : 8),
),
child: ExpansionTile(
title: Text(
'User Trips',
style: TextStyle(
fontSize: isWeb ? 20 : 18,
fontWeight: FontWeight.bold,
color: Colors.blue.shade800,
),
),
initiallyExpanded: true,
childrenPadding: EdgeInsets.all(isWeb ? 16 : 12),
children: [
if (showSortControls && (isWeb || forWebLayout))
Align(
alignment: Alignment.centerRight,
child: DropdownButton<String>(
value: _tripSortOption,
items: [
DropdownMenuItem(value: 'recent', child: Text('Most Recent')),
DropdownMenuItem(value: 'distance', child: Text('Longest Distance')),
],
onChanged: (value) => _setTripSort(value!),
),
),
SizedBox(height: 12),
SizedBox(
height: effectiveHeight - 80,
child: _isLoadingTrips
? Center(child: CircularProgressIndicator())
: _userTrips.isEmpty
? Center(
child: Text(
_selectedUser == null
? 'Select a user to view trips'
: 'No trips found',
style: TextStyle(color: Colors.grey),
),
)
: ListView.separated(
physics: const ClampingScrollPhysics(),
itemCount: _userTrips.length,
separatorBuilder: (context, index) => Divider(height: 1, thickness: 0.5, indent: isWeb ? 72 : 60),
itemBuilder: (context, index) {
final trip = _userTrips[index];
final startTime = trip['start_time'] != null
? TripService.formatTimestamp(trip['start_time'])
: 'Unknown time';
final distance = (trip['distance'] ?? 0).toDouble();
final duration = (trip['duration'] ?? 0).toDouble();
                    return ListTile(
            dense: true,
  visualDensity: VisualDensity.compact,
  contentPadding: EdgeInsets.symmetric(horizontal: isWeb ? 8 : 4),
                      leading: Icon(Icons.directions_car, size: isWeb ? 24 : 20, color: Colors.blue.shade800),
                      title: Text(
                        startTime,
                        style: TextStyle(fontSize: isWeb ? 14 : 13, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${distance.toStringAsFixed(1)} miles • ${duration.toStringAsFixed(1)} min',
                        style: TextStyle(fontSize: isWeb ? 12 : 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.info_outline, size: isWeb ? 20 : 18),
                        onPressed: () {
                          if (trip['trip_id'] != null) {
                            TripService.showTripDetails(context, trip);
                          }
                        },
                      ),
                    );
                  },
                ),
    ),
  ],
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
    
    setState(() {
      _foundUsers = results.map((user) {
        // Create a display string that shows all available info
        String displayInfo = '';
        if (user['user_id'] != null) displayInfo += 'ID: ${user['user_id']} ';
        if (user['first_name'] != null && user['last_name'] != null) {
          displayInfo += '${user['first_name']} ${user['last_name']} ';
        }
        if (user['email'] != null) displayInfo += '(${user['email']})';
        
        return {
          'user_id': user['user_id'],
          'name': displayInfo.trim(), // Show combined info
          'email': user['email'] ?? 'No email',
          'role': user['role'] ?? 'user',
          'first_name': user['first_name'],
          'last_name': user['last_name'],
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

// Update the API call methods to validate the userId parameter
Future<void> _loadUserScore(String userId) async {
  if (userId.isEmpty) {
    setState(() {
      _searchError = 'Invalid user ID';
    });
    return;
  }

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
  if (userId.isEmpty) {
    setState(() {
      _searchError = 'Invalid user ID';
    });
    return;
  }

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