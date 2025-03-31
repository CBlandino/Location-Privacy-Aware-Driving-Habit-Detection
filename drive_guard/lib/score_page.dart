import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class ScorePage extends StatelessWidget {
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
            SizedBox(height: screenHeight*.07), // Adjust vertical spacing
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
            SizedBox(height: screenHeight*.03), // Adjust vertical spacing
            Align(
              alignment: Alignment.center,
              child: Text(
                'Your Current Score: ${score.toInt()}%',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: screenHeight*.04), // Adjust vertical spacing
            Align(
              alignment: Alignment.center,
              child: Container(
                width: screenWidth * .7,
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
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    
                  ),
                  onPressed: () {},
                  child: Text('View Full Report'),
                ),
              ),
            ),
          ],
        ),
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