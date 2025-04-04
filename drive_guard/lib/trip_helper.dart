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
        return data.isNotEmpty ? data : _getDummyData();
      } else {
        print('Error fetching trips');
        return _getDummyData();
      }
    } catch (error) {
      print('Error: $error');
      return _getDummyData();
    }
  }

static String formatTimestamp(dynamic timestamp) {
  try {
    print("Raw timestamp: $timestamp");

    DateTime dateTime;

    if (timestamp is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    } else if (timestamp is String) {
      try {
        dateTime = DateTime.parse(timestamp); // Try ISO 8601
      } catch (_) {
        // Fallback to custom format
        dateTime = DateFormat("MM/dd/yyyy HH:mm").parse(timestamp);
      }
    } else {
      throw FormatException("Unknown timestamp format");
    }

    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} "
           "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  } catch (e) {
    print("Error parsing timestamp: $e");
    return "Invalid timestamp";
  }
}

  static List<Map<String, dynamic>> _getDummyData() {
    return [
      {"timestamp": 1711910400, "distance": 10.0},
      {"timestamp": 1711996800, "distance": 8.5},
      {"timestamp": 1712083200, "distance": 12.3},
    ];
  }
}
