import 'package:flutter/material.dart';
//import 'package:intl/intl.dart'; // Import for date formatting
import 'package:intl/intl.dart';
import 'custom_app_bar.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'ipconfig.dart';
import 'login_page.dart';
import 'trip_helper.dart';

class PreviousTripsPage extends StatefulWidget {
  @override
  _PreviousTripsPageState createState() => _PreviousTripsPageState();
}

class _PreviousTripsPageState extends State<PreviousTripsPage> {
  List<dynamic> trips = [];
  final String server = AppConfig.server;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _checkAuthToken();
    fetchPreviousTrips();
  }

  Future<void> _checkAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    // if (token == null || JwtDecoder.isExpired(token)) {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (context) => LoginPageWidget()),
    //   );
    // }
  }

Future<void> fetchPreviousTrips() async {
  List<dynamic> data = await TripService.fetchPreviousTrips();
  if (mounted) {
    setState(() {
      trips = data;
    });
  }
}


List<Map<String, dynamic>> _getDummyData() {
  return [
    {"timestamp": 1711910400, "distance": 10.0},
    {"timestamp": 1711996800, "distance": 8.5},
    {"timestamp": 1712083200, "distance": 12.3},
  ];
}

void _showTripDetails(Map<String, dynamic> trip) {
  int timestamp;
  
  try {
    timestamp = int.parse(trip['timestamp']); // Convert string to int
  } catch (e) {
    print('Error parsing timestamp: $e');
    timestamp = 0; // Fallback in case of error
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Trip Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Start Time: ${timestamp > 0 ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000) : 'Invalid timestamp'}"),
            Text("Distance: ${trip['distance']} meters"),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Close"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

String formatTimestamp(dynamic timestamp) {
  try {
    // Ensure timestamp is an integer
    int time = (timestamp is String) ? int.parse(timestamp) : timestamp;
    
    // Convert to DateTime and format
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} "
           "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  } catch (e) {
    print("Error parsing timestamp: $e");
    return "Invalid timestamp";
  }
}

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index; // Switches pages     
      });
    }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        selectedIndex: 1,
        onItemTapped: _onItemTapped,
      ),
      body: trips.isEmpty
          ? Center(child: Text("No trips available"))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  columns: [
                    DataColumn(label: Text("Start Time")),
                    DataColumn(label: Text("Distance (m)")),
                    DataColumn(label: Text("Actions")),
                  ],
                  rows: trips.map((trip) {
                    return DataRow(cells: [
                      DataCell(Text(formatTimestamp(trip['timestamp']))),
                      DataCell(Text(trip['distance'].toString())),
                      DataCell(
                        ElevatedButton(
                          child: Text("Expand Trip"),
                          onPressed: () => _showTripDetails(trip),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),//:_pages[_selectedIndex],
      bottomNavigationBar: CustomAppBar(
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
    )
    .buildBottomNavBar(context),
    );
  }
}