import 'package:flutter/material.dart';
import 'custom_drawer.dart';
import 'current_trip_page.dart';
import 'previous_trips_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomePage extends StatelessWidget {
  final String role;
  const HomePage({super.key, required this.role});
  final String server = 'http://10.0.2.2:8080';

  Future<List<dynamic>> fetchPreviousTrips() async {
    final String url = '$server/previous_trips'; // Example URL for your server
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load trips');
      }
    } catch (error) {
      throw Exception('Failed to load trips: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('$role Dashboard'),
        backgroundColor: Colors.blue.shade700,
      ),
      drawer: CustomDrawer(role: role), // Custom drawer for navigation
      body: Column(
        children: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CurrentTripPage()),
              );
            },
            child: Text('Start New Trip'),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: fetchPreviousTrips(), // Provide the future here
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No previous trips available'));
                }

                List<dynamic> trips = snapshot.data!;
                return ListView.builder(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
