import 'package:flutter/material.dart';

class UserScorePage extends StatelessWidget {
  final String userId;
  final Map<String, dynamic>? scoreData;
  final bool isLoading;
  final String errorMessage;

  const UserScorePage({
    required this.userId,
    this.scoreData,
    required this.isLoading,
    required this.errorMessage,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Enter User ID',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {}, // Handle search
        ),
        SizedBox(height: 20),
        if (isLoading)
          Center(child: CircularProgressIndicator()),
        if (errorMessage.isNotEmpty)
          Text(errorMessage, style: TextStyle(color: Colors.red)),
        if (scoreData != null)
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Safety Score: ${scoreData!['score']}',
                      style: TextStyle(fontSize: 24)),
                  SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: scoreData!['score'] / 100,
                  ),
                  SizedBox(height: 10),
                  Text('Trips analyzed: ${scoreData!['tripCount']}'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}