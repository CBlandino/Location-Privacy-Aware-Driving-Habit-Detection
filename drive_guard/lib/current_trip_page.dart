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

//currently for the "Widget _buildDeltaList()" the points stay 0. Also the program is not consistant, sometimes it takes 1 to four 4 seconds to start making delta point data

class CurrentTripPage extends StatefulWidget {
  @override
  _CurrentTripPageState createState() => _CurrentTripPageState();
}

class _CurrentTripPageState extends State<CurrentTripPage> {
  bool isTripStarted = false; // Flag to track if the trip is ongoing
  bool isLoading = true;
  Timer? _deltaTimer;
  Timer? _elapsedTimeTimer;
  Timer? _sendDataTimer;
  DateTime? tripStartTime;
  int _elapsedTime = 0; // Timer in seconds
  int? _previousMaskedLatitude, _previousMaskedLongitude; // Masked lat/lon of the previous location
  List<Map<String, dynamic>> deltaPoints = []; // Store delta-compressed data with timestamps\
  List<Map<String, dynamic>> deltaPointsClone = [];
  int _pointCounter = 0; // To track the number of delta points calculated
  int? _firstMaskedLatitude, _firstMaskedLongitude; // Store the first masked latitude and longitude
  final String server = AppConfig.server; // Server address
  int _selectedIndex = 0;



  // Random number generator for test data
  Random rand = Random();

  // Variables for the initial simulated latitude and longitude
  late double _initialLatitude;
  late double _initialLongitude;
  late String role;

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
  _loadUserInfo();
  _requestPermissions(); // Ensure permissions are requested on startup
  _loadFirstPoint().then((_) {
    Geolocator.getCurrentPosition();
    setState(() {});  
  });
}


Future<void> _loadUserInfo() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  role = prefs.getString('role')!;
  //String? firstName = prefs.getString('first_name');
  //String? lastName = prefs.getString('last_name');
  //String? email = prefs.getString('email');
   setState((){
      isLoading = false;
  });

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
  
Future<void> _showTripStartingDialog(int seconds) async {
  int remaining = seconds;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          // Start countdown only once
          Future.delayed(Duration.zero, () async {
            for (int i = seconds; i > 0; i--) {
              await Future.delayed(Duration(seconds: 1));
              if (Navigator.of(context).canPop()) {
                setState(() {
                  remaining = i - 1;
                });
              } else {
                return;
              }
            }

            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(); // Close dialog
            }
          });

          return AlertDialog(
            title: Text("Warming up GPS"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Starting trip in $remaining seconds..."),
              ],
            ),
          );
        },
      );
    },
  );
}


Future<void> startTrip() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    await _requestPermissions(); // Request permission if not granted
    permission = await Geolocator.checkPermission();
  }

 if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
  setState(() {
    isTripStarted = true;
    deltaPoints.clear();
    deltaPointsClone.clear();
    _elapsedTime = 0;
    _pointCounter = 0;
    tripStartTime = DateTime.now();
  });

  await _showTripStartingDialog(5); // shows 5 second countdown

print("Warming up GPS...");
for (int i = 0; i < 5; i++) {
  try {
    Position warmupPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print("Warmup #$i → Lat: ${warmupPosition.latitude}, Lon: ${warmupPosition.longitude}");
    await Future.delayed(Duration(seconds: 1));
  } catch (e) {
    print("Warmup error: $e");
  }
}

    print("GPS warmup complete. Starting timers.");

  // Start listening to GPS updates
  _deltaTimer = Timer.periodic(Duration(seconds: 5), (timer) {
    _getCurrentLocation();
  });

  _elapsedTimeTimer = Timer.periodic(Duration(seconds: 1), (timer) {
    setState(() {
      _elapsedTime++;
    });
  });

  _sendDataTimer = Timer.periodic(Duration(seconds: 30), (timer) {
    sendTripData();
  });
}
else {
    _showPermissionDialog("Location permission is required to start the trip.");
  }
}

// Stop the trip but KEEP delta points visible
void stopTrip() async {

  setState(() {
    isTripStarted = false; // Stops the trip but keeps everything visible
  });

  // Send remaining data but DO NOT clear `deltaPoints` or reset UI
  if(_elapsedTime > 5)
  {sendTripData();}

  // Stop all timers
  _deltaTimer?.cancel();
  _elapsedTimeTimer?.cancel();
  _sendDataTimer?.cancel();
  
  // Forces UI refresh without clearing data
  setState(() {});
}

bool _isGettingLocation = false;
Future<void> _getCurrentLocation() async {
if (_isGettingLocation) return;
  _isGettingLocation = true;

  try {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    int maskedLatitude = (position.latitude * 1000000).toInt();
    int maskedLongitude = (position.longitude * 1000000).toInt();

    if (_firstMaskedLatitude == null || _firstMaskedLongitude == null) {
      _storeFirstPoint(maskedLatitude, maskedLongitude);
      _firstMaskedLatitude = maskedLatitude;
      _firstMaskedLongitude = maskedLongitude;
      _previousMaskedLatitude = maskedLatitude;
      _previousMaskedLongitude = maskedLongitude;
      return;
    }

    if (_previousMaskedLatitude != null && _previousMaskedLongitude != null) {
      int deltaLat = maskedLatitude - _previousMaskedLatitude!;
      int deltaLon = maskedLongitude - _previousMaskedLongitude!;

      setState(() {
        deltaPoints.insert(0, {
          'dlat': deltaLat,
          'dlon': deltaLon,
          't': DateTime.now().toIso8601String(),
          'p': _pointCounter,
        });

        deltaPointsClone.insert(0, {
          'delta_latitude': deltaLat,
          'delta_longitude': deltaLon,
          'point_number': _pointCounter,
        });

        _pointCounter++;

      });
    }

    _previousMaskedLatitude = maskedLatitude;
    _previousMaskedLongitude = maskedLongitude;
  } catch (e) {
    print("Error getting location: $e");
  }finally {
    _isGettingLocation = false;
}
}

  // Send trip data to the server
  Future<void> sendTripData() async {
    final String url = '$server/trip';
    // Retrieve token from shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    //Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);

    // if (JwtDecoder.isExpired(token)) {
    //   //print("No authentication token found.");
    //   Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (context) => LoginPageWidget()), // Redirect to login
    //   );
    //   return;
    // }
   
    Map<String, dynamic> data = {
      'isStart' : _elapsedTime <= 30,
      'start_time': DateTime.now().toIso8601String(),
      'elapsed_time': _elapsedTime,
      'delta_points': deltaPoints,
      'isEnd' : !isTripStarted,
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

      if (response.statusCode == 202) {
         
        deltaPoints.clear(); //delta points are currently being cleared, clone the delta points into another list for the map
      
      } else {
        print('Error sending trip data');
      }
    } catch (error) {
      print('Error: $error');
    }

    //setState(() {
    //  deltaPoints.clear();
    //});
  }

// Updated full widget build and related methods for screen responsiveness
@override
Widget build(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;

  return WillPopScope(
    onWillPop: () async {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(role: role)),
      );
      return false;
    },
    child: Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: isLoading
          ? null
          : CustomAppBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        role:role,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(screenWidth * 0.02),
        child: Column(
          children: [
            _buildStatusCard(screenWidth),
            SizedBox(height: screenHeight * 0.02),
            _buildTimerCard(screenWidth),
            SizedBox(height: screenHeight * 0.02),
            _buildMapView(screenHeight, screenWidth),
            SizedBox(height: screenHeight * 0.01),
            _buildDeltaList(screenHeight, screenWidth),
            SizedBox(height: screenHeight * 0.02),
            _buildActionButton(screenWidth),
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
      bottomNavigationBar:  isLoading
          ? null
          : CustomAppBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        role:role,
      ).buildBottomNavBar(context),
    ),
  );
}

Widget _buildStatusCard(double screenWidth) {
  return Card(
    elevation: 5,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Center(
        child: Text(
          'Trip Status: ${isTripStarted ? "Ongoing" : "Stopped"}',
          style: TextStyle(fontSize: screenWidth * 0.055, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    ),
  );
}

Widget _buildTimerCard(double screenWidth) {
  return Card(
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
    shadowColor: Colors.black38,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        color: Colors.white,
      ),
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, color: Colors.blue, size: screenWidth * 0.08),
          SizedBox(width: screenWidth * 0.03),
          Text(
            'Elapsed Time: ${formatElapsedTime()}',
            style: TextStyle(fontSize: screenWidth * 0.055, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    ),
  );
}

Widget _buildDeltaList(double screenHeight, double screenWidth) {
  return Container(
    height: screenHeight * 0.2,
    child: Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
      shadowColor: Colors.black26,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.02),
        child: deltaPointsClone.isNotEmpty
            ? ListView.builder(
                //key: ValueKey(deltaPointsClone.length),
                itemCount: deltaPointsClone.length,
                itemBuilder: (context, index) {
                  var delta = deltaPointsClone[index];
                  return ListTile(
                    leading: Icon(Icons.location_on, color: Colors.redAccent),
                    title: Text("Point #${delta['point_number']}", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("ΔLat: ${delta['delta_latitude']}, ΔLon: ${delta['delta_longitude']}"),
                    tileColor: index % 2 == 0 ? Colors.grey[100] : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
                  );
                },
              )
            : Center(
                child: Text(
                  "No data available",
                  style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.04),
                ),
              ),
      ),
    ),
  );
}

Widget _buildMapView(double screenHeight, double screenWidth) {
  return Container(
    height: screenHeight * 0.25,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(screenWidth * 0.03),
      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: screenWidth * 0.015)],
    ),
    child: Padding(
      padding: EdgeInsets.all(screenWidth * 0.02),
      child: deltaPointsClone.isNotEmpty
          ? CustomPaint(
              painter: RoutePainter(deltaPointsClone),
              child: Container(),
            )
          : Center(
              child: Text(
                "No route data available",
                style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.04),
              ),
            ),
    ),
  );
}

Widget _buildActionButton(double screenWidth) {
  return Container(
    margin: EdgeInsets.only(top: screenWidth * 0.05),
    width: double.infinity,
    child: ElevatedButton(
      onPressed: isTripStarted ? stopTrip : startTrip,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.1,
          vertical: screenWidth * 0.05,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.08)),
        elevation: 10,
        backgroundColor: isTripStarted ? Colors.redAccent : Colors.greenAccent,
        foregroundColor: Colors.white,
        shadowColor: Colors.black,
      ),
      child: Text(
        isTripStarted ? 'Stop Trip' : 'Start Trip',
        style: TextStyle(fontSize: screenWidth * 0.065, fontWeight: FontWeight.bold),
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

class CountdownDialog extends StatefulWidget {
  final int initialSeconds;

  const CountdownDialog({super.key, required this.initialSeconds});

  @override
  _CountdownDialogState createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<CountdownDialog> {
  late int remaining;

  @override
  void initState() {
    super.initState();
    remaining = widget.initialSeconds;
    _startCountdown();
  }

  void _startCountdown() async {
    while (remaining > 0) {
      await Future.delayed(Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        remaining--;
      });
    }
    if (mounted) {
      Navigator.of(context).pop(); // Close the dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Warming up GPS"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Starting trip in $remaining seconds..."),
        ],
      ),
    );
  }
}
