import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PreviousTripsPage extends StatefulWidget {
  @override
  _PreviousTripsPageState createState() => _PreviousTripsPageState();
}

class _PreviousTripsPageState extends State<PreviousTripsPage> {
  List<dynamic> trips = [];

  final String server = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    fetchPreviousTrips();
  }

  Future<void> fetchPreviousTrips() async {
    final String url = '$server/previous_trips'; // Example URL for your server
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          trips = json.decode(response.body);
        });
      } else {
        print('Error fetching trips');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Previous Trips")),
      body: ListView.builder(
        itemCount: trips.length,
        itemBuilder: (context, index) {
          var trip = trips[index];
          return ListTile(
            title: Text('Trip #${trip['id']}'),
            subtitle: Text('Duration: ${trip['elapsed_time']} seconds'),
            onTap: () {
              // Navigate to detailed trip page
            },
          );
        },
      ),
    );
  }
}
