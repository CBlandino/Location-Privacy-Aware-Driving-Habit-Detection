import 'package:flutter/material.dart';
//import 'package:intl/intl.dart'; // Import for date formatting
//import 'package:intl/intl.dart';
import 'custom_app_bar.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'ipconfig.dart';
import 'login_page.dart';

class PreviousTripsPage extends StatefulWidget {
  @override
  _PreviousTripsPageState createState() => _PreviousTripsPageState();
}

class _PreviousTripsPageState extends State<PreviousTripsPage> {
  List<dynamic> trips = [];
  final String server = AppConfig.server;

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
  final String url = '$server/previous_trips'; 
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        trips = data.isNotEmpty ? data : _getDummyData();
      });
    } else {
      print('Error fetching trips');
      setState(() {
        trips = _getDummyData();
      });
    }
  } catch (error) {
    print('Error: $error');
    setState(() {
      trips = _getDummyData();
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Trip Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Start Time: ${DateTime.fromMillisecondsSinceEpoch(trip['timestamp'] * 1000)}"),
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

//   // Function to format the timestamp
// String formatTimestamp(int timestamp) {
//   DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
//   return DateFormat('MM/dd/yyyy HH:mm').format(date);
// }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        selectedIndex: 1,
        onItemTapped: (index) {
          setState(() {});
        },
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
//                      DataCell(Text(formatTimestamp(trip['timestamp']))),
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
            ),
    );
  }
}