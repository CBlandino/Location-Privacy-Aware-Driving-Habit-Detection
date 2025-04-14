import 'package:flutter/material.dart';
//import 'package:intl/intl.dart'; // Import for date formatting
import 'package:intl/intl.dart';
import 'custom_app_bar.dart';
import 'package:http/http.dart' as http;
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
  late String role;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    fetchPreviousTrips();
  }

Future<void> _loadUserInfo() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  role = prefs.getString('user_role')!;
  //String? firstName = prefs.getString('user_first_name');
  //String? lastName = prefs.getString('user_last_name');
  //String? email = prefs.getString('user_email');

  if (role == null) {
    print('role not found.');
  } 
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
    timestamp = trip['timestamp'] is int
    ? trip['timestamp']
    : DateTime.parse(trip['timestamp']).millisecondsSinceEpoch ~/ 1000;
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
        role: role,
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
                      DataCell(Text(TripService.formatTimestamp(trip['timestamp']))),
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
      role: role,
    )
    .buildBottomNavBar(context),
    );
  }
}