import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'custom_app_bar.dart';

class ScorePage extends StatefulWidget {
  @override
  _ScorePage createState() => _ScorePage();
}

class _ScorePage extends State<ScorePage> {
  // implement functionality in future
  final double score = 85;
  int _selectedIndex = 2;


  // actual dynamic data
  /*
  double? score; // nullable so we can show loading
  Map<String, String> breakdown = {};
  bool isLoading = true;
  String errorMessage = '';




  @override
  void initState() {
    super.initState();
    fetchScoreData();
  }

  Future<void> fetchScoreData() async {
    try {
      final response = await http.get(Uri.parse('http://your-go-backend/api/score'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          score = data['score'].toDouble();
          breakdown = Map<String, String>.from(data['breakdown']);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load score data.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  
*/



  //const ScorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Score'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight*.07),
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
            SizedBox(height: screenHeight*.03),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Your Current Score: ${score.toInt()}%',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: screenHeight*.04), 
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
                      offset: Offset(0, 4), // Soft shadow
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
                        )
                      ),
                      onPressed: () {},
                      child: Text('View Full Report'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomAppBar(
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
    )
    .buildBottomNavBar(context),
    );
  }

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index; // Switches pages     
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


  // Function to determine color based on score
  Color scoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}



/*
Score will be socre of all trips combined
for now make it out of 100





*/