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
  String? token = prefs.getString('auth_token');

  if (token == null || JwtDecoder.isExpired(token)) {
    Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => LoginPageWidget()), // Redirect to login
    );
  }
}

  Future<void> fetchPreviousTrips() async {
    final String url = '$server/previous_trips'; 
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
