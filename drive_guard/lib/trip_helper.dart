import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'ipconfig.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripService {
  static final String server = AppConfig.server;

static Future<List<Map<String, dynamic>>> searchInsurance(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.server}/admin/search_insurance?query=$query'),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      throw Exception('Failed to search insurance companies');
    } catch (e) {
      throw Exception('Search error: $e');
    }
  }

  static Future<bool> checkServerStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.server}/ping'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

    static Future<void> createAdminAccount({
    required String email,
    required String password,
    required String serverNumber,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.server}/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'server_number': serverNumber,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create admin account: ${response.body}');
    }
  }

  static Future<void> createUserAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.server}/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'role': 'user',
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create user account: ${response.body}');
    }
  }

    static Future<void> createInsuranceAccount({
    required String email,
    required String password,
    required String companyName,
    required String state,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.server}/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'company_name': companyName,
        'state': state,
        'role': 'insurance',
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create insurance account: ${response.body}');
    }
  }


static void showTripDetails(BuildContext context, Map<String, dynamic> trip) {
  // Parse the start time
  DateTime startTime;
  try {
    if (trip['timestamp'] is String) {
      startTime = DateTime.parse(trip['timestamp']);
    } else if (trip['timestamp'] is int) {
      startTime = DateTime.fromMillisecondsSinceEpoch(trip['timestamp'] * 1000);
    } else {
      startTime = DateTime.now();
    }
  } catch (e) {
    startTime = DateTime.now();
  }

  // Calculate duration - convert from minutes to milliseconds if needed
  double durationMinutes = (trip['duration'] ?? 0).toDouble();
  DateTime endTime = startTime.add(Duration(minutes: durationMinutes.round()));

  final avgSpeed = trip['velocity']?.toDouble() ?? 0.0;
  final maxSpeed = trip['max_velocity']?.toDouble() ?? 0.0;

showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  "Trip Details",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  Icons.calendar_today,
                  "Date:",
                  DateFormat('MMM dd, yyyy').format(startTime),
                ),
                _buildDetailRow(
                  context,
                  Icons.access_time,
                  "Start Time:",
                  DateFormat('hh:mm a').format(startTime),
                ),
                _buildDetailRow(
                  context,
                  Icons.timer,
                  "Duration:",
                  "${durationMinutes.toStringAsFixed(1)} minutes",
                ),
                _buildDetailRow(
                  context,
                  Icons.timer,
                  "End Time:",
                  DateFormat('hh:mm a').format(endTime),
                ),
                _buildDetailRow(
                  context,
                  Icons.directions_car,
                  "Distance:",
                  "${trip['distance']?.toStringAsFixed(2) ?? 'N/A'} miles",
                ),
            _buildDetailRow(
              context,
              Icons.speed,
              "Max Speed:",
              "${maxSpeed.toStringAsFixed(1)} mph",
            ),
                        _buildDetailRow(
              context,
              Icons.speed,
              "Average Speed:",
              "${avgSpeed.toStringAsFixed(1)} mph",
            ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    },
  );
}
static Widget buildTripListItem(BuildContext context, Map<String, dynamic> trip) {
  final avgSpeed = trip['average_speed']?.toDouble() ?? 0.0;
  
  return ListTile(

    subtitle: Text(
      '${trip['distance']?.toStringAsFixed(1) ?? '0.0'} miles • '
      '${avgSpeed.toStringAsFixed(1)} mph',
    ),
  );
}


static double calculateTotalDistance(List<dynamic> trips) {
  return trips.fold(0.0, (sum, trip) => sum + (trip['distance'] ?? 0.0));
}

static String calculateAvgTime(List<dynamic> trips) {
  if (trips.isEmpty) return '0';
  final avg = trips.fold(0.0, (sum, trip) => sum + (trip['duration'] ?? 0)) / trips.length;
  return avg.toStringAsFixed(1);
}

static Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        )),
        const SizedBox(width: 5),
        Text(value, style: const TextStyle(
          color: Color.fromARGB(255, 78, 78, 78),
        )),
      ],
    ),
  );
}

static Future<List<Map<String, dynamic>>> fetchPreviousTripsData() async {
  final String url = '$server/previoustrips';
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('access_token');

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      
      // Transform the data to include both original and new fields
      return data.map((trip) {
        // Original fields
        Map<String, dynamic> tripData = {
          'trip_id': trip['trip_id'],
          'user_id': trip['user_id'],
          'timestamp': trip['timestamp'],
          'distance': (trip['distance'] ?? 0).toDouble(),
          'duration': (trip['duration'] ?? 0).toDouble(),
          'average_speed': (trip['average_speed'] ?? 0).toDouble(),
          'max_speed': (trip['max_speed'] ?? 0).toDouble(),
          'data': trip['data'], // Original trip data if exists
        };

        // New score-related fields (with fallbacks if not available)
        tripData.addAll({
          'brake_score': (trip['brake_score'] ?? trip['metrics']?['brake_score'] ?? 0).toDouble(),
          'accel_score': (trip['accel_score'] ?? trip['metrics']?['accel_score'] ?? 0).toDouble(),
          'trip_score': (trip['trip_score'] ?? trip['metrics']?['trip_score'] ?? 0).toDouble(),
          // Convert scores if they're stored as percentages (e.g., 85 instead of 0.85)
          'brake_score_percent': ((trip['brake_score'] ?? trip['metrics']?['brake_score'] ?? 0) * 100).toDouble(),
          'accel_score_percent': ((trip['accel_score'] ?? trip['metrics']?['accel_score'] ?? 0) * 100).toDouble(),
          'trip_score_percent': ((trip['trip_score'] ?? trip['metrics']?['trip_score'] ?? 0) * 100).toDouble(),
        });

        return tripData;
      }).toList();
    } else {
      throw Exception('Failed to fetch trips: ${response.statusCode}');
    }
  } catch (error) {
    throw Exception('Failed to fetch trips: $error');
  }
}

  static Future<List<dynamic>> fetchPreviousTrips() async {
    final String url = '$server/previoustrips';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data; 
      } else {
        return [];
      }
    } catch (error) {
       return [];
    }
  }

static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
  final uri = Uri.parse('$server/userLookup').replace(
    queryParameters: {'query': query}
  );
  
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('access_token');

  try {
    final response = await http.get(
      uri, 
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      // Extract the users array from the response
      if (data['users'] is List) {
        return List<Map<String, dynamic>>.from(data['users']);
      }
      throw Exception('Invalid users data format');
    } else {
      throw Exception('Failed to search users: ${response.statusCode}');
    }
  } catch (error) {
    throw Exception('Search failed: $error');
  }
}

static Future<Map<String, dynamic>> getUserScore(String userId) async {
  final String url = '$server/user_score/$userId';
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('access_token');

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Convert scores to proper decimal format
      double convertScore(dynamic score) {
        if (score == null) return 0.0;
        double value = score.toDouble();
        // If score appears to be multiplied by 100 (like 9929 instead of 99.29)
        if (value > 100 && value <= 10000) {
          return value / 100;
        }
        return value;
      }

      return {
        'score': convertScore(data['score']),
        'accel_score': convertScore(data['accel_score']),
        'brake_score': convertScore(data['brake_score']),
        'user_id': data['user_id']?.toString() ?? userId,
        'first_name': data['first_name'] ?? '',
        'last_name': data['last_name'] ?? '',
        'trip_count': data['trip_count'] ?? 0,
        'all_trips': data['all_trips'] ?? [],
        'calculation': data['calculation'] ?? {},
        'updated_at': data['updated_at'] ?? DateTime.now().toString(),
      };
    } else {
      throw Exception('Failed to get user score: ${response.statusCode}');
    }
  } catch (error) {
    throw Exception('Failed to fetch score: $error');
  }
}

static Future<List<Map<String, dynamic>>> getUserTrips(String userId, {String? sortBy}) async {
  String url = '$server/user_trips/$userId';
  if (sortBy != null) {
    url += '?sort=$sortBy';
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('access_token');

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> trips = data['trips'] ?? [];
      return trips.map((trip) {
        // Ensure we have valid values, default to 0 if null
        return {
          'trip_id': trip['trip_id'],
          'user_id': trip['user_id'],
          'timestamp': trip['timestamp'],
          'distance': (trip['distance'] ?? 0).toDouble(),
          'duration': (trip['duration'] ?? 0).toDouble(),
          'average_speed': (trip['average_speed'] ?? 0).toDouble(),
          'max_speed': (trip['max_speed'] ?? 0).toDouble(),         
        };
      }).toList();
    } else {
      throw Exception('Failed to get user trips: ${response.statusCode}');
    }
  } catch (error) {
    throw Exception('Failed to fetch trips: $error');
  }
}

static String formatTimestamp(dynamic timestamp,{bool dateOnly = false}) {
  if (timestamp == null) {
    return "No date";
  }
  try {
    DateTime dateTime;

    // Handle integer timestamps (seconds or milliseconds since epoch)
    if (timestamp is int) {
      // More reliable way to detect milliseconds vs seconds
      final int threshold = 10000000000; // 20 Nov 2286 in seconds
      dateTime = timestamp > threshold 
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    }
    // Handle string timestamps
    else if (timestamp is String) {
      // Try ISO 8601 format first (most common API format)
      if (timestamp.contains("T")) {
        print("containts T");
      final dateTime = DateTime.parse(timestamp).toUtc().toLocal();
      return DateFormat('MM/dd/yyyy HH:mm').format(dateTime);
      } 
      // Try common alternate formats
      else if (timestamp.contains("/")) {
        dateTime = DateFormat("MM/dd/yyyy HH:mm").parse(timestamp);
      }
      else if (timestamp.contains("-")) {
        dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(timestamp);
      }
      else {
        throw FormatException("Unrecognized date format");
      }
    }
    // Handle DateTime objects directly
    else if (timestamp is DateTime) {
      dateTime = timestamp;
    }
    else {
      throw FormatException("Unsupported timestamp type: ${timestamp.runtimeType}");
    }

    // Format the final output
      return dateOnly 
      ? DateFormat('MMM d, yyyy').format(dateTime)
      : DateFormat('MMM d, yyyy · hh:mm a').format(dateTime);
  } catch (e) {
    debugPrint("Timestamp parsing error: $e");
    debugPrint("Original timestamp value: $timestamp");
    return "Invalid date";
  }
}
}
