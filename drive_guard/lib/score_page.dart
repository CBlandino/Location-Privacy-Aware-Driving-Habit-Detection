import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class ScorePage extends StatelessWidget {
  // implement functionality in future
  final double score = 85; // Example score

  const ScorePage({super.key});

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
    );
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