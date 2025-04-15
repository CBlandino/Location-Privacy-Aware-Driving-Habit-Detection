import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'ipconfig.dart';
import 'package:flutter/material.dart';
//import 'package:intl/intl.dart'; // Import for date formatting
import 'package:intl/intl.dart';
import 'custom_app_bar.dart';
import 'ipconfig.dart';
import 'login_page.dart';

class TripService {
  static final String server = AppConfig.server;

  // Add these methods to your TripService class in trip_helper.dart

static void showTripDetails(BuildContext context, Map<String, dynamic> trip) {
  int timestamp;
  try {
    timestamp = trip['timestamp'] is int
        ? trip['timestamp']
        : DateTime.parse(trip['timestamp']).millisecondsSinceEpoch ~/ 1000;
  } catch (e) {
    timestamp = 0;
  }

  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Trip Details",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(context, Icons.calendar_today, "Date:", 
                  timestamp > 0 ? DateFormat('MMM dd, yyyy').format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)) : 'N/A'),
              _buildDetailRow(context, Icons.access_time, "Time:", 
                  timestamp > 0 ? DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)) : 'N/A'),
              _buildDetailRow(context, Icons.directions_car, "Distance:", 
                  "${trip['distance']?.toStringAsFixed(2) ?? 'N/A'} miles"),
              _buildDetailRow(context, Icons.speed, "Average Speed:", 
                  "${trip['velocity']?.toStringAsFixed(1) ?? 'N/A'} mph"),
              _buildDetailRow(context, Icons.timer, "Duration:", 
                  "${trip['duration']?.toStringAsFixed(1) ?? 'N/A'} minutes"),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, 
                    backgroundColor: Colors.blue[800],
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      );
    },
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

  static Future<List<dynamic>> fetchPreviousTrips() async {
    final String url = '$server/previous_trips';
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
        print('Error fetching trips');
        return [];
      }
    } catch (error) {
      print('Error: $error');
       return [];
    }
  }

static String formatTimestamp(dynamic timestamp) {
  if (timestamp == null) {
    return "No date";
  }

print("Raw timestamp received: $timestamp (Type: ${timestamp.runtimeType})");

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
        dateTime = DateTime.parse(timestamp).toLocal();
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
    return DateFormat('MMM d, yyyy · hh:mm a').format(dateTime);
  } catch (e) {
    debugPrint("Timestamp parsing error: $e");
    debugPrint("Original timestamp value: $timestamp");
    return "Invalid date";
  }
}
}
