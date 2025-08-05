import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'custom_app_bar.dart';
import 'home_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ipconfig.dart';

class CurrentTripPage extends StatefulWidget {
  @override
  CurrentTripPageState createState() => CurrentTripPageState();
}

class CurrentTripPageState extends State<CurrentTripPage> {
  bool isTripStarted = false;
  bool isLoading = true;
  Timer? _deltaTimer;
  Timer? _elapsedTimeTimer;
  Timer? _sendDataTimer;
  DateTime? tripStartTime;
  int _elapsedTime = 0;
  int? _previousMaskedLatitude, _previousMaskedLongitude;
  List<Map<String, dynamic>> deltaPoints = [];
  List<Map<String, dynamic>> deltaPointsClone = [];
  int _pointCounter = 0;
  int? _firstMaskedLatitude, _firstMaskedLongitude;
  final String server = AppConfig.server;
  int _selectedIndex = 0;

  Random rand = Random();

  late String role;

  Future<void> _loadFirstPoint() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstMaskedLatitude = prefs.getInt('first_latitude');
      _firstMaskedLongitude = prefs.getInt('first_longitude');
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
    _requestPermissions();
    _loadFirstPoint().then((_) {
      Geolocator.getCurrentPosition();
      setState(() {});
    });
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    role = prefs.getString('role')!;
    setState(() {
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
      debugPrint(
        "Location permissions are permanently denied. Please enable them in app settings.",
      );
      _showPermissionDialog(
        "Location permission is permanently denied. Please enable it in settings.",
      );
    } else if (permission == LocationPermission.denied) {
      // If permission is denied (not permanently), inform the user that permission was denied
      debugPrint("Location permission was denied.");
      _showPermissionDialog(
        "Location permission was denied. Please enable it to use this feature.",
      );
    } else {
      // Permission granted
      debugPrint("Location permission granted.");
    }
  }

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
                _openAppSettings();
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

  Future<void> _openAppSettings() async {
    bool opened = await Geolocator.openAppSettings();
    if (!opened) {
      debugPrint('Could not open app settings.');
    }
  }

  Future<void> _showLoadingDialog(String message) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  Future<void> startTrip() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await _requestPermissions(); // Request permission if not granted
      permission = await Geolocator.checkPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      setState(() {
        isTripStarted = true;
        deltaPoints.clear();
        deltaPointsClone.clear();
        _elapsedTime = 0;
        _pointCounter = 0;
        tripStartTime = DateTime.now();
      });

      await _showLoadingDialog("Getting ready... warming up GPS");

      // wakes up GPS
      debugPrint("Waking up GPS...");
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // let GPS stabilize
      await Future.delayed(Duration(seconds: 3));

      debugPrint("Getting accurate location...");
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint("Accurate: ${pos.latitude}, ${pos.longitude}");

      debugPrint("GPS warmup complete. Starting timers.");
      Navigator.of(context, rootNavigator: true).pop();

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
    } else {
      _showPermissionDialog(
        "Location permission is required to start the trip.",
      );
    }
  }

  // Stop the trip but KEEP delta points visible
  void stopTrip() async {
    setState(() {
      isTripStarted = false; // Stops the trip but keeps everything visible
    });

    // Send remaining data but DO NOT clear `deltaPoints` or reset UI
    if (_elapsedTime > 5) {
      sendTripData();
    }

    // Stop all timers
    _deltaTimer?.cancel();
    _elapsedTimeTimer?.cancel();
    _sendDataTimer?.cancel();

    // Forces UI refresh without clearing data
    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
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
    }
  }

  Future<void> sendTripData() async {
    final String url = '$server/points';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    Map<String, dynamic> data = {
      'isStart': _elapsedTime <= 30,
      'start_time': DateTime.now().toIso8601String(),
      'elapsed_time': _elapsedTime,
      'delta_points': deltaPoints,
      'isEnd': !isTripStarted,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 202) {
        deltaPoints.clear();
      } else {
        debugPrint('Error sending trip data');
      }
    } catch (error) {
      debugPrint('Error: $error');
    }
  }

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
        appBar:
            isLoading
                ? null
                : CustomAppBar(
                  selectedIndex: _selectedIndex,
                  onItemTapped: _onItemTapped,
                  role: role,
                ),
        body:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
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
                      SizedBox(height: screenHeight * 0.01),
                      _buildActionButton(screenWidth),
                      SizedBox(height: screenHeight * 0.01),
                    ],
                  ),
                ),
        bottomNavigationBar:
            isLoading
                ? null
                : CustomAppBar(
                  selectedIndex: _selectedIndex,
                  onItemTapped: _onItemTapped,
                  role: role,
                ).buildBottomNavBar(context),
      ),
    );
  }

  Widget _buildStatusCard(double screenWidth) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
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
            style: TextStyle(
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCard(double screenWidth) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
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
              style: TextStyle(
                fontSize: screenWidth * 0.055,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
        ),
        shadowColor: Colors.black26,
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.02),
          child:
              deltaPointsClone.isNotEmpty
                  ? ListView.builder(
                    itemCount: deltaPointsClone.length,
                    itemBuilder: (context, index) {
                      var delta = deltaPointsClone[index];
                      return ListTile(
                        leading: Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                        ),
                        title: Text(
                          "Point #${delta['point_number']}",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "ΔLat: ${delta['delta_latitude']}, ΔLon: ${delta['delta_longitude']}",
                        ),
                        tileColor:
                            index % 2 == 0 ? Colors.grey[100] : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ),
                        ),
                      );
                    },
                  )
                  : Center(
                    child: Text(
                      "No data available",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: screenWidth * 0.04,
                      ),
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
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: screenWidth * 0.015),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.02),
        child:
            deltaPointsClone.isNotEmpty
                ? CustomPaint(
                  painter: RoutePainter(deltaPointsClone),
                  child: Container(),
                )
                : Center(
                  child: Text(
                    "No route data available",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: screenWidth * 0.04,
                    ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.08),
          ),
          elevation: 10,
          backgroundColor:
              isTripStarted ? Colors.redAccent : Colors.greenAccent,
          foregroundColor: Colors.white,
          shadowColor: Colors.black,
        ),
        child: Text(
          isTripStarted ? 'Stop Trip' : 'Start Trip',
          style: TextStyle(
            fontSize: screenWidth * 0.065,
            fontWeight: FontWeight.bold,
          ),
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

    Paint pathPaint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

    Paint pointPaint =
        Paint()
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
    List<Offset> scaledOffsets =
        offsets.map((o) {
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
  CountdownDialogState createState() => CountdownDialogState();
}

class CountdownDialogState extends State<CountdownDialog> {
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
      Navigator.of(context).pop();
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
