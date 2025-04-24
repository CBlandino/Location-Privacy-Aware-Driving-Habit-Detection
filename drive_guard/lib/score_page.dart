import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;
import 'dart:convert';
import 'custom_app_bar.dart';
import 'current_trip_page.dart';

class ScorePage extends StatefulWidget {
  @override
  _ScorePage createState() => _ScorePage();
}

class _ScorePage extends State<ScorePage> {
  double score = 0;
  int _selectedIndex = 2;
  late String role;
  bool isLoading = true;

  // Static data for testing
  Map<String, String> breakdown = {};

 @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    role = prefs.getString('role')!;

    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://18.191.9.236:8080/ca1cd3c3055991bf20499ee86739f7e2'), 
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );


    if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          isLoading = false;
          score = data['totalScore']?.toInt() ?? 0;
          breakdown = {
            "Braking": _ratingLabel(data['braking']),
            "Acceleration": _ratingLabel(data['acceleration']),
            "Speed Control": _ratingLabel(data['speedControl']),
          };
        });
      } else {
        print('Failed to load score');
        setState(() {
          isLoading = false;
        });
      }
  }

  String _ratingLabel(double? value) {
      if (value == null) return "Unknown";
      if (value >= 90) return "Excellent";
      if (value >= 70) return "Good";
      if (value >= 50) return "Average";
      return "Needs Improvement";
    }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Score'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : score == 0
        ? _buildNoTripsYet(context)
        : Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * .07),
              Align(
                alignment: Alignment.center,
                child: CircularPercentIndicator(
                  radius: 100.0,
                  lineWidth: 12.0,
                  percent: score / 100,
                  center: Text(
                    "${score.toInt()}%",
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  progressColor: scoreColor(score),
                  backgroundColor: Colors.grey[300]!,
                  circularStrokeCap: CircularStrokeCap.round,
                  animation: true,
                  animationDuration: 1000,
                ),
              ),
              SizedBox(height: screenHeight * .03),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Your Current Score: ${score.toInt()}%',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: screenHeight * .04),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: screenWidth * .8,
                  height: screenHeight * .3,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 1, 84, 143),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Score Breakdown",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          // replace with name of habit, and severity
                          _buildScoreDetail("Smoothness", "Good"),
                          _buildScoreDetail("Braking", "Needs Improvement"),
                          _buildScoreDetail("Acceleration", "Excellent"),
                          _buildScoreDetail("Cornering", "Average"),
                          _buildScoreDetail("Speed Control", "Good"),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            isScrollControlled: true,
                            builder: (BuildContext context) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "Full Driving Report",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Divider(),
                                    ...breakdown.entries.map((entry) => ListTile(
                                          leading: Icon(Icons.check_circle_outline,
                                              color: Colors.blue.shade700),
                                          title: Text(entry.key),
                                          trailing: Text(
                                            entry.value,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _ratingColor(entry.value),
                                            ),
                                          ),
                                        )),
                                    SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text("Close"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade700,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Text('View Full Report'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      bottomNavigationBar:  isLoading
        ? null
        : CustomAppBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
            role: role,
          ).buildBottomNavBar(context),
    );
  }

  Widget _buildNoTripsYet(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No trips recorded yet",
            style: TextStyle(
              fontSize: 18, 
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.blue[800],
            ),
            onPressed: () {
              Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CurrentTripPage()),
              );
            },
            child: const Text("Start a new trip"),
          ),
        ],
      ),
    );
  }








  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildScoreDetail(String category, String rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            category,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          Text(
            rating,
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color scoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _ratingColor(String rating) {
    switch (rating.toLowerCase()) {
      case "excellent":
        return Colors.green;
      case "good":
        return Colors.orange;
      case "average":
        return Colors.amber;
      case "needs improvement":
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}


/*
Score will be socre of all trips combined
for now make it out of 100





*/