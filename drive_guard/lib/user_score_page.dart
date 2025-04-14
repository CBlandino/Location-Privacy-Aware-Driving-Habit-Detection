import 'package:flutter/material.dart';

class UserScorePage extends StatelessWidget {
  final String userId;
  final Map<String, dynamic>? scoreData;
  final bool isLoading;
  final String errorMessage;
  final Function(String)? onSearchSubmitted;

  const UserScorePage({
    this.userId = '',
    this.scoreData,
    this.isLoading = false,
    this.errorMessage = '',
    this.onSearchSubmitted,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Enter User ID',
            hintText: 'e.g., user12345',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.search),
          ),
          controller: TextEditingController(text: userId),
          onSubmitted: onSearchSubmitted,
        ),
        SizedBox(height: 20),
        
        if (isLoading)
          Center(child: CircularProgressIndicator()),
        
        if (errorMessage.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        
        if (!isLoading && errorMessage.isEmpty)
          _buildScoreContent(),
      ],
    );
  }

  Widget _buildScoreContent() {
    if (userId.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.score, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Enter a User ID to view their safety score',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (scoreData == null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.help_outline, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No score data available for user $userId',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final score = scoreData!['score']?.toDouble() ?? 0.0;
    final maxScore = scoreData!['max_score']?.toDouble() ?? 100.0;
    final tripCount = scoreData!['trip_count'] ?? 0;

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Safety Score',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: score / maxScore,
                    strokeWidth: 12,
                    color: _getScoreColor(score, maxScore),
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                Text(
                  '${score.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Based on $tripCount ${tripCount == 1 ? 'trip' : 'trips'}',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 20),
            if (scoreData?['last_updated'] != null)
              Text(
                'Last updated: ${_formatDate(scoreData!['last_updated'])}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score, double maxScore) {
    final percentage = score / maxScore;
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.6) return Colors.lightGreen;
    if (percentage >= 0.4) return Colors.yellow;
    if (percentage >= 0.2) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }
}