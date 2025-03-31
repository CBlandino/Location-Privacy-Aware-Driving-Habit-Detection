import 'package:flutter/material.dart';
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

    if (token == null || JwtDecoder.isExpired(token)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPageWidget()),
      );
    }
  }

  Future<void> fetchPreviousTrips() async {
    final String url = '$server/previous_trips'; 
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          trips = data.isNotEmpty ? data : [];
        });
      } else {
        print('Error fetching trips');
        setState(() {
          trips = [];
        });
      }
    } catch (error) {
      print('Error: $error');
      setState(() {
        trips = [];
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Previous Trips"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchPreviousTrips,
          ),
        ],
      ),
      body: trips.isEmpty
          ? Center(child: Text("No trips available"))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text("Start Time")),
                  DataColumn(label: Text("Distance (m)")),
                  DataColumn(label: Text("Actions")),
                ],
                rows: trips.map((trip) {
                  return DataRow(cells: [
                    DataCell(Text(DateTime.fromMillisecondsSinceEpoch(trip['timestamp'] * 1000).toString())),
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
    );
  }
}
