import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PreviousTripsPage extends StatefulWidget {
  @override
  _PreviousTripsPageState createState() => _PreviousTripsPageState();
}

class _PreviousTripsPageState extends State<PreviousTripsPage> {
  List<dynamic> trips = [];

  @override
  void initState() {
    super.initState();
    fetchPreviousTrips();
  }

  Future<void> fetchPreviousTrips() async {
    final String url = 'http://10.0.2.2:6969/previous_trips'; // Server URL
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
