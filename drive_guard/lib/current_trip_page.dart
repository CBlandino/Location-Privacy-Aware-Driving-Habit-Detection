import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart'; // Import Geolocator package
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class CurrentTripPage extends StatefulWidget {
  @override
  _CurrentTripPageState createState() => _CurrentTripPageState();
}

class _CurrentTripPageState extends State<CurrentTripPage> {
  bool isTripStarted = false; // Flag to track if the trip is ongoing
  late Timer _deltaTimer;
  late Timer _elapsedTimeTimer;
  late Timer _sendDataTimer;
  int _elapsedTime = 0; // Timer in seconds
  int? _previousMaskedLatitude, _previousMaskedLongitude; // Masked lat/lon of the previous location
  List<Map<String, dynamic>> deltaPoints = []; // Store delta-compressed data with timestamps
  int _pointCounter = 0; // To track the number of delta points calculated
  int? _firstMaskedLatitude, _firstMaskedLongitude; // Store the first masked latitude and longitude
  final String server = 'http://10.0.2.2:8080'; // Server address

  // Random number generator for test data
  Random rand = Random();

  // Variables for the initial simulated latitude and longitude
  late double _initialLatitude;
  late double _initialLongitude;

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

@override
void initState() {
  super.initState();
  
  // Ensure data only resets when the page is re-entered, NOT when stopping a trip
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!isTripStarted) {
      setState(() {
        _elapsedTime = 0;
        deltaPoints.clear(); // Clear only when the page is reopened
      });
    }
  });

  _initialLatitude = (rand.nextDouble() * 180) - 90;
  _initialLongitude = (rand.nextDouble() * 360) - 180;

  _loadFirstPoint();
}

@override
void dispose() {
  // Only stop timers but do NOT clear delta points
  _deltaTimer.cancel();
  _elapsedTimeTimer.cancel();
  _sendDataTimer.cancel();

  super.dispose(); // Properly disposes of the widget without modifying state
}

  // Method to format the elapsed time into HH:MM:SS, MM:SS, or just seconds
  String formatElapsedTime() {
    int hours = _elapsedTime ~/ 3600;
    int minutes = (_elapsedTime % 3600) ~/ 60;
    int seconds = _elapsedTime % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$seconds sec';
    }
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

  // Start the trip simulation
  void startTrip() {
    setState(() {
      isTripStarted = true;
    });

    // Request location permissions when the trip starts
    _requestPermissions();

    // Start the timer for calculating delta points every 0.25 seconds
    _deltaTimer = Timer.periodic(Duration(milliseconds: 250), (timer) {
      _pointCounter++;
      _getSimulatedLocation();  // Simulated GPS updates
    });

    // Start the timer for tracking elapsed time
    _elapsedTimeTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime++;
      });
    });

    // Start the timer for sending data every minute
    _sendDataTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      sendTripData();
    });
  }

// Stop the trip but keep delta points visible
void stopTrip() async {
  setState(() {
    isTripStarted = false;
  });

  // Stop all timers
  _deltaTimer.cancel();
  _elapsedTimeTimer.cancel();
  _sendDataTimer.cancel();

  // Send remaining data but DO NOT clear deltaPoints
  await sendTripData();

  // Force UI refresh so the delta points remain visible
  setState(() {});
}

  // Simulate location updates by generating random deltas
  void _getSimulatedLocation() {
    // Generate random lat/lon changes within a small range
    double randomLatChange = (rand.nextDouble() - 0.5) * 0.01;
    double randomLonChange = (rand.nextDouble() - 0.5) * 0.01;

    double newLatitude = _initialLatitude + randomLatChange;
    double newLongitude = _initialLongitude + randomLonChange;

    // Convert lat/lon to whole numbers for masking precision
    int maskedLatitude = (newLatitude * 1000000).toInt();
    int maskedLongitude = (newLongitude * 1000000).toInt();

    // Store the first point if not already set
    if (_firstMaskedLatitude == null || _firstMaskedLongitude == null) {
      _storeFirstPoint(maskedLatitude, maskedLongitude);
    }



    // Compute delta changes
    if (_previousMaskedLatitude != null && _previousMaskedLongitude != null) {
      int deltaLat = maskedLatitude - _previousMaskedLatitude!;
      int deltaLon = maskedLongitude - _previousMaskedLongitude!;

      // Store delta points
      setState(() {
        deltaPoints.insert(0, {
          'delta_latitude': deltaLat,
          'delta_longitude': deltaLon,
          'timestamp': DateTime.now().toIso8601String(),
          'point_number': _pointCounter,
        });
      });
    }

    // Update previous values
    _previousMaskedLatitude = maskedLatitude;
    _previousMaskedLongitude = maskedLongitude;
  }

  // Send trip data to the server
  Future<void> sendTripData() async {
    final String url = '$server/trip';
    Map<String, dynamic> data = {
      'start_time': DateTime.now().toIso8601String(),
      'elapsed_time': _elapsedTime,
      'delta_points': deltaPoints,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        print("Trip data sent successfully!");
      } else {
        print('Error sending trip data');
      }
    } catch (error) {
      print('Error: $error');
    }

    setState(() {
      deltaPoints.clear();
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[200],
    appBar: AppBar(title: Text("Current Trip")),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildStatusCard(),
          SizedBox(height: 20),
          _buildTimerCard(),
          SizedBox(height: 20),
          _buildMapView(), // New map section
          SizedBox(height: 10),
          _buildDeltaList(), // Smaller delta points section
          Spacer(),
          _buildActionButton(), // More prominent button
        ],
      ),
    ),
  );
}


// Build trip status card with a gradient background
Widget _buildStatusCard() {
  return Card(
    elevation: 5,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text(
          'Trip Status: ${isTripStarted ? "Ongoing" : "Stopped"}',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    ),
  );
}

// Build elapsed time card with better styling
Widget _buildTimerCard() {
  return Card(
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    shadowColor: Colors.black38,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, color: Colors.blue, size: 30),
          SizedBox(width: 10),
          Text(
            'Elapsed Time: ${formatElapsedTime()}',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    ),
  );
}

// Build delta points section that remains visible after stopping trip
Widget _buildDeltaList() {
  return Container(
    height: 150,
    child: Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      shadowColor: Colors.black26,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: deltaPoints.isNotEmpty
            ? ListView.builder(
                itemCount: deltaPoints.length,
                itemBuilder: (context, index) {
                  var delta = deltaPoints[index];
                  return ListTile(
                    leading: Icon(Icons.location_on, color: Colors.redAccent),
                    title: Text("Point #${delta['point_number']}", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("ΔLat: ${delta['delta_latitude']}, ΔLon: ${delta['delta_longitude']}"),
                    tileColor: index % 2 == 0 ? Colors.grey[100] : Colors.white, // Alternating colors
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  );
                },
              )
            : Center(
                child: Text(
                  "No data available",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
      ),
    ),
  );
}

// Build map visualization that persists after stopping trip
Widget _buildMapView() {
  return Container(
    height: 200,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
    ),
    child: Padding(
      padding: EdgeInsets.all(8),
      child: deltaPoints.isNotEmpty
          ? CustomPaint(
              painter: RoutePainter(deltaPoints), // Use custom painter to draw route
              child: Container(),
            )
          : Center(
              child: Text(
                "No route data available",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
    ),
  );
}

// Build start/stop button with standout UI
Widget _buildActionButton() {
  return Container(
    margin: EdgeInsets.only(top: 20),
    width: double.infinity,
    child: ElevatedButton(
      onPressed: isTripStarted ? stopTrip : startTrip,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 10,
        backgroundColor: isTripStarted ? Colors.redAccent : Colors.greenAccent,
        foregroundColor: Colors.white,
        shadowColor: Colors.black,
      ),
      child: Text(
        isTripStarted ? 'Stop Trip' : 'Start Trip',
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
}


class RoutePainter extends CustomPainter {
  final List<Map<String, dynamic>> points;

  RoutePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return; // Need at least two points to draw a path

    Paint pathPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    Paint pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Validate and extract lat/lon values
    List<int> latitudes = points.map((p) => p['delta_latitude'] as int).toList();
    List<int> longitudes = points.map((p) => p['delta_longitude'] as int).toList();

    if (latitudes.isEmpty || longitudes.isEmpty) return; // Ensure no crashes

    double minLat = latitudes.isNotEmpty ? latitudes.reduce(min).toDouble() : 0;
    double maxLat = latitudes.isNotEmpty ? latitudes.reduce(max).toDouble() : 1;
    double minLon = longitudes.isNotEmpty ? longitudes.reduce(min).toDouble() : 0;
    double maxLon = longitudes.isNotEmpty ? longitudes.reduce(max).toDouble() : 1;

    // Prevent division by zero (ensure the difference is non-zero)
    double scaleX = (maxLon - minLon) != 0 ? size.width / (maxLon - minLon) : 1;
    double scaleY = (maxLat - minLat) != 0 ? size.height / (maxLat - minLat) : 1;

    List<Offset> offsets = points.map((point) {
      double x = ((point['delta_longitude'] as int) - minLon) * scaleX;
double y = size.height - ((point['delta_latitude'] as int) - minLat) * scaleY;
      return Offset(x, y);
    }).toList();

    if (offsets.length < 2) return; // Ensure there are enough points to draw

    Path path = Path();
    path.moveTo(offsets.first.dx, offsets.first.dy);
    for (var offset in offsets.skip(1)) {
      path.lineTo(offset.dx, offset.dy);
    }

    canvas.drawPath(path, pathPaint);

    // Draw the points on the path
    for (var offset in offsets) {
      canvas.drawCircle(offset, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

