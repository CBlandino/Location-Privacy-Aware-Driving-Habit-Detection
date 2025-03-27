import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'custom_app_bar.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator package
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'ipconfig.dart';



class CurrentTripPage extends StatefulWidget {
  @override
  _CurrentTripPageState createState() => _CurrentTripPageState();
}

class _CurrentTripPageState extends State<CurrentTripPage> {
  bool isTripStarted = false; // Flag to track if the trip is ongoing
  Timer? _deltaTimer;
  Timer? _elapsedTimeTimer;
  Timer? _sendDataTimer;
  DateTime? tripStartTime;
  int _elapsedTime = 0; // Timer in seconds
  int? _previousMaskedLatitude, _previousMaskedLongitude; // Masked lat/lon of the previous location
  List<Map<String, dynamic>> deltaPoints = []; // Store delta-compressed data with timestamps
  int _pointCounter = 0; // To track the number of delta points calculated
  int? _firstMaskedLatitude, _firstMaskedLongitude; // Store the first masked latitude and longitude
  final String server = AppConfig.server; // Server address
  int _selectedIndex = 0;

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

      void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index; // Switches pages     
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
  _checkAuthToken();

  // Only reset when page is reopened, NOT when stopping/starting trip
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!isTripStarted) {
      // Removed clearing of data on trip stop
      setState(() {
        _elapsedTime = 0;
        // deltaPoints.clear();  DO NOT CLEAR
      });
    }
  });

  _initialLatitude = (rand.nextDouble() * 180) - 90;
  _initialLongitude = (rand.nextDouble() * 360) - 180;

_loadFirstPoint().then((_) {
    setState(() {});  // Ensure UI updates when data is loaded
  });
}

Future<void> _checkAuthToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');
  Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);

  // if (JwtDecoder.isExpired(token)) {
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(builder: (context) => LoginPageWidget()),
  //   );
  // }
}

@override
void dispose() {
  // Only stop timers but do NOT clear delta points or reset UI
  _deltaTimer?.cancel();
  _elapsedTimeTimer?.cancel();
  _sendDataTimer?.cancel();

  super.dispose();
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
    // Reset all trip-related data for a new session
    isTripStarted = true;
    deltaPoints.clear(); // Clear previous trip data
    _elapsedTime = 0; // Reset elapsed time
    _pointCounter = 0; // Reset point counter
    tripStartTime = DateTime.now(); // Mark new trip start time

    _previousMaskedLatitude = _initialLatitude.toInt();
    _previousMaskedLongitude = _initialLongitude.toInt();
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

  // Ensure UI refresh
  setState(() {});
}

// Stop the trip but KEEP delta points visible
void stopTrip() async {
  setState(() {
    isTripStarted = false; // Stops the trip but keeps everything visible
  });

  // Stop all timers
  _deltaTimer?.cancel();
  _elapsedTimeTimer?.cancel();
  _sendDataTimer?.cancel();

  // Send remaining data but DO NOT clear `deltaPoints` or reset UI
  if(_elapsedTime > 5)
  {sendTripData();}
  
  // Forces UI refresh without clearing data
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
            //print("Total Points: ${deltaPoints.length}");
            //print("Latest Point: ΔLat=${deltaLat}, ΔLon=${deltaLon}");
      });
    }

    // Update previous values
    _previousMaskedLatitude = maskedLatitude;
    _previousMaskedLongitude = maskedLongitude;

    setState(() {});  // Ensure UI updates with the new data
  }

  // Send trip data to the server
  Future<void> sendTripData() async {
    final String url = '$server/trip';
      // Retrieve token from shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
  Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);

    // if (JwtDecoder.isExpired(token)) {
    //   //print("No authentication token found.");
    //   Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (context) => LoginPageWidget()), // Redirect to login
    //   );
    //   return;
    // }
   
    Map<String, dynamic> data = {
      'isStart' : isTripStarted,
      'start_time': DateTime.now().toIso8601String(),
      'elapsed_time': _elapsedTime,
      'delta_points': deltaPoints,
      'isEnd' : isTripStarted,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Include token
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        //print("Trip data sent successfully!");
      } else {
        //print('Error sending trip data');
      }
    } catch (error) {
      print('Error: $error');
    }

    //setState(() {
    //  deltaPoints.clear();
    //});
  }

@override
Widget build(BuildContext context) {
      return WillPopScope(
    onWillPop: () async {
      // Navigate back to HomePage instead of the last screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(role: "user")), // Pass role 
      );
      return false; // Prevent default back navigation
    },
  child: Scaffold(
    backgroundColor: Colors.grey[200],
    
    // Use CustomAppBar instead of default AppBar
    appBar: CustomAppBar(
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
    ),

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

    // Bottom Navigation Bar from CustomAppBar
    bottomNavigationBar: CustomAppBar(
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
    ).buildBottomNavBar(context),
  ));
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

// Keep delta points visible after stopping trip
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
                key: ValueKey(deltaPoints.length), // Ensures widget rebuilds correctly
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
  //print("Rendering Map with ${deltaPoints.length} points");
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
    if (points.length < 2) return; // Need at least two points to draw

    Paint pathPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    Paint pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Convert delta values into absolute positions
    int baseLat = 0;
    int baseLon = 0;

    List<Offset> offsets = [];
    for (int i = points.length - 1; i >= 0; i--) { 
      baseLat += points[i]['delta_latitude'] as int;
      baseLon += points[i]['delta_longitude'] as int;
      offsets.add(Offset(baseLon.toDouble(), -baseLat.toDouble())); 
    }

    if (offsets.length < 2) return; // Ensure enough points to draw

    // Find min/max for scaling
    double minX = offsets.map((o) => o.dx).reduce(min);
    double maxX = offsets.map((o) => o.dx).reduce(max);
    double minY = offsets.map((o) => o.dy).reduce(min);
    double maxY = offsets.map((o) => o.dy).reduce(max);

    double scaleX = (maxX - minX) != 0 ? size.width / (maxX - minX) : 1;
    double scaleY = (maxY - minY) != 0 ? size.height / (maxY - minY) : 1;

    // Normalize the points to fit within the canvas
    List<Offset> scaledOffsets = offsets.map((o) {
      double x = (o.dx - minX) * scaleX;
      double y = size.height - (o.dy - minY) * scaleY;
      return Offset(x, y);
    }).toList();

    Path path = Path();
    path.moveTo(scaledOffsets.first.dx, scaledOffsets.first.dy);
    for (var offset in scaledOffsets.skip(1)) {
      path.lineTo(offset.dx, offset.dy);
    }

    // Draw the path
    canvas.drawPath(path, pathPaint);

    // Draw the points
    for (var offset in scaledOffsets) {
      canvas.drawCircle(offset, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; 
  }
}
