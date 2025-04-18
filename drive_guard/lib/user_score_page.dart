import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

import 'custom_app_bar.dart';

class UserScorePage extends StatefulWidget {
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
  _UserScorePageState createState() => _UserScorePageState();
}

class _UserScorePageState extends State<UserScorePage> {
  int _selectedIndex = 2; // Set to 2 for User Scores tab
  final TextEditingController _userIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userIdController.text = widget.userId;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        role: 'insurance',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter User ID',
                hintText: 'e.g., user12345',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              controller: _userIdController,
              onSubmitted: widget.onSearchSubmitted,
            ),
            SizedBox(height: 20),
            if (widget.isLoading)
              Container(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(child: CircularProgressIndicator()),
              ),
            if (widget.errorMessage.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  widget.errorMessage,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            if (!widget.isLoading && widget.errorMessage.isEmpty)
              _buildScoreContent(widget.userId, widget.scoreData),
          ],
        ),
      ),
      bottomNavigationBar: CustomAppBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        role: 'insurance',
      ).buildBottomNavBar(context),
    );
  }

  Widget _buildScoreContent(dynamic userId, dynamic scoreData) {
    if (userId.isEmpty) {
      return _buildMessage("Enter a User ID to view their safety score", Icons.score);
    }

    if (scoreData == null) {
      return _buildMessage("No score data available for user $userId", Icons.help_outline);
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

  Widget _buildMessage(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
        ],
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
