import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;
import 'dart:convert';
import 'custom_app_bar.dart';
import 'current_trip_page.dart';
import 'graph_Score_Page.dart';

class ScorePage extends StatefulWidget {
  @override
  _ScorePage createState() => _ScorePage();
}

class _ScorePage extends State<ScorePage> {
  int score = 0;
  int _selectedIndex = 2;
  late String role;
  bool isLoading = true;



  Map<String, String> breakdown = {};   // Map receiving from backend. Key is the name of the habit, value is the severity


 @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    role = prefs.getString('role')!;

    final token = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('http://18.191.9.236:8080/ca1cd3c3055991bf20499ee86739f7e2'), 
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // TODO Replace breakdown with correct names in database
    if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          isLoading = false;

            final rawScore = data['totalScore'] ?? 0.0;
            final roundedScore = double.parse(rawScore.toStringAsFixed(2));

            score = (roundedScore * 100).toInt();
          print('User Score : ${data['totalScore']}');
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

  String _ratingLabel(num? value) {
      if (value == null) return "Unknown";

final double val = value.toDouble();


  if (val >= 0.90) return "Excellent";
  if (val >= 0.70) return "Good";
  if (val >= 0.50) return "Average";
  return "Needs Improvement";
    }


@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return Scaffold(
    appBar: AppBar(
      title: const Text(
        'Your Score',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.blue.shade700,
      elevation: 0,
    ),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : score == 0
            ? _buildNoTripsYet(context)
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircularPercentIndicator(
                      radius: 100.0,
                      lineWidth: 12.0,
                      percent: score / 100,
                      center: Text(
                        "$score%",
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                      ),
                      progressColor: scoreColor(score),
                      backgroundColor: Colors.grey[300]!,
                      circularStrokeCap: CircularStrokeCap.round,
                      animation: true,
                      animationDuration: 1000,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your Current Score: $score%',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF01548F),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Score Breakdown",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...breakdown.entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                  Text(
                                    entry.value,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                _showFullReportModal(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue.shade800,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: const Text("View Full Report"),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  MiniScoreGraph(
                    scores: [0.72, 0.85, 0.88, 0.91, 0.95, 1.0], // Replace with real data
                  ),
                  ],
                ),
              ),
    bottomNavigationBar: isLoading
        ? null
        : CustomAppBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
            role: role,
          ).buildBottomNavBar(context),
  );
}

// Extracted method for cleaner code
void _showFullReportModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
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
            const SizedBox(height: 16),
            const Text(
              "Full Driving Report",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Divider(),
            ...breakdown.entries.map(
              (entry) => ListTile(
                leading: Icon(Icons.check_circle_outline, color: Colors.blue.shade700),
                title: Text(entry.key),
                trailing: Text(
                  entry.value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _ratingColor(entry.value),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    },
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

  Color scoreColor(int score) {
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