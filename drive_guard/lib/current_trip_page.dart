import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';  // Import shared_preferences

class CurrentTripPage extends StatefulWidget {
  @override
  _CurrentTripPageState createState() => _CurrentTripPageState();
}

class _CurrentTripPageState extends State<CurrentTripPage> {
  bool isTripStarted = false;
  late Timer _deltaTimer;
  late Timer _elapsedTimeTimer;
  late Timer _sendDataTimer;
  int _elapsedTime = 0; // Timer in seconds
  late Position _currentPosition;
  int? _previousMaskedLatitude, _previousMaskedLongitude; // Masked lat/lon of the previous location
  List<Map<String, dynamic>> deltaPoints = []; // Store delta-compressed data with timestamps
  int _pointCounter = 0; // To track the number of delta points calculated
  int? _firstMaskedLatitude, _firstMaskedLongitude; // Store the first masked latitude and longitude
  final String server = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    _loadFirstPoint(); // Load the first point when the app starts
  }

  // Request location permissions at runtime
  Future<void> _requestPermissions() async {
    // Check the current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // If permission is denied, request the permission
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      // If the permission is denied permanently, inform the user to enable it manually in settings
      print("Location permissions are permanently denied. Please enable them in app settings.");
      _showPermissionDialog("Location permission is permanently denied. Please enable it in settings.");
    } else if (permission == LocationPermission.denied) {
      // If permission is denied (not permanently), inform the user that permission was denied
      print("Location permission was denied.");
      _showPermissionDialog("Location permission was denied. Please enable it to use this feature.");
    } else {
      // Permission granted
      print("Location permission granted.");
    }
  }

  // Show permission dialog when location permissions are denied
  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permission Required'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _openAppSettings(); // Open the app settings for the user to enable permissions
                Navigator.of(context).pop();
              },
              child: Text('Go to Settings'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Open app settings to allow the user to manually enable permissions
  Future<void> _openAppSettings() async {
    bool opened = await Geolocator.openAppSettings();
    if (!opened) {
      print('Could not open app settings.');
    }
  }

  // Load the first masked latitude and longitude from shared preferences
  Future<void> _loadFirstPoint() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstMaskedLatitude = prefs.getInt('first_latitude');
      _firstMaskedLongitude = prefs.getInt('first_longitude');
    });
  }

  // Store the first masked latitude and longitude to shared preferences
  Future<void> _storeFirstPoint(int maskedLatitude, int maskedLongitude) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('first_latitude', maskedLatitude);
    await prefs.setInt('first_longitude', maskedLongitude);
    setState(() {
      _firstMaskedLatitude = maskedLatitude;
      _firstMaskedLongitude = maskedLongitude;
    });
  }

  // Method to start the trip
  void startTrip() {
    setState(() {
      isTripStarted = true;
    });

    // Request location permissions when the trip starts
    _requestPermissions();

    // Start the timer that triggers every 0.25 seconds for calculating delta points
    _deltaTimer = Timer.periodic(Duration(milliseconds: 250), (timer) {
      _pointCounter++;
      _getLocation();
    });

    // Start the elapsed time timer that increments every second to show the user the time in seconds
    _elapsedTimeTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime++;
      });
    });

    // Start the timer that triggers every 1 minute to send delta points to the server
    _sendDataTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      sendTripData();
    });
  }

  // Method to stop the trip
  void stopTrip() async {
    setState(() {
      isTripStarted = false;
    });

    // Stop the delta point calculation, elapsed time, and data sending timers
    _deltaTimer.cancel();
    _elapsedTimeTimer.cancel();
    _sendDataTimer.cancel();

    // Send the remaining delta points to the server
    await sendTripData();
  }

  // Method to get the user's location
  Future<void> _getLocation() async {
    // Check if permission is granted before fetching location
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      // Fetch the location if permission is granted
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });

      // Mask location by multiplying by 6 to get whole numbers
      int maskedLatitude = (position.latitude * 6).round();
      int maskedLongitude = (position.longitude * 6).round();

      // If it's the first point, store it
      if (_firstMaskedLatitude == null || _firstMaskedLongitude == null) {
        await _storeFirstPoint(maskedLatitude, maskedLongitude); // Store the first point
      }

      // Delta compression: Calculate the difference from the previous point
      if (_previousMaskedLatitude != null && _previousMaskedLongitude != null) {
        // Calculate delta latitude and delta longitude
        int deltaLat = maskedLatitude - _previousMaskedLatitude!;
        int deltaLon = maskedLongitude - _previousMaskedLongitude!;

        Map<String, dynamic> deltaData = {
          'delta_latitude': deltaLat,
          'delta_longitude': deltaLon,
          'timestamp': DateTime.now().toIso8601String(),
          'point_number': _pointCounter,
        };
        deltaPoints.add(deltaData); // Store the delta-compressed point with timestamp
      }

      // Update the previous coordinates for the next delta compression
      _previousMaskedLatitude = maskedLatitude;
      _previousMaskedLongitude = maskedLongitude;
    } else {
      // Permission not granted, notify the user
      print("Location permission is required to access the location.");
    }
  }

  // Send delta-compressed data to the server
  Future<void> sendTripData() async {
    final String url = '$server/trip'; // Example URL for your server
    Map<String, dynamic> data = {
      'start_time': DateTime.now().toIso8601String(),
      'elapsed_time': _elapsedTime,
      'delta_points': deltaPoints, // Send all the delta-compressed points with timestamp
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        // Handle success
        print("Trip data sent successfully!");
      } else {
        // Handle error
        print('Error sending trip data');
      }
    } catch (error) {
      print('Error: $error');
    }

    // Reset the delta points after sending
    setState(() {
      deltaPoints.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Current Trip")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Time: $_elapsedTime seconds',  // Timer shown in seconds
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isTripStarted ? stopTrip : startTrip,
              child: Text(isTripStarted ? 'Stop Trip' : 'Start Trip'),
            ),
          ],
        ),
      ),
    );
  }
}
