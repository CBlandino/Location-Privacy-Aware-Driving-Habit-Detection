import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;
import 'dart:convert';
import 'custom_app_bar.dart';
import 'current_trip_page.dart';
import 'graph_Score_Page.dart';
import 'trip_helper.dart';
import 'ipconfig.dart';


class ScorePage extends StatefulWidget {
  @override
  _ScorePage createState() => _ScorePage();
}

class _ScorePage extends State<ScorePage> {
  int score = 0;
  int _selectedIndex = 2;
  late String role;
  bool isLoading = true;

  final String server = AppConfig.server;




  // Used for graph
  List<double> scores = [];     // Will hold users all previous trip scores 
  List<String> dates = [];      // Currently unfunctional, will hold all dates for corresponding scores



  Map<String, String> breakdown = {};   // Map receiving from backend. Key is the name of the habit, value is the severity

  // Initialize states, load users info, and load trip data gor graph
 @override
  void initState() {
    super.initState();
    _loadUserInfo();
    loadTripData();
  }

  // Loads the type of user (user, admin, service provider)
  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    role = prefs.getString('role')!;

    final token = prefs.getString('access_token');

    final responseScore = await http.get(
      Uri.parse('$server/score'), 
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );


    // TODO Replace breakdown with correct names in database
    if (responseScore.statusCode == 200) {
        final data = json.decode(responseScore.body);
        setState(() {
          isLoading = false;

            final rawScore = data['totalScore'] ?? 0.0;
            final roundedScore = double.parse(rawScore.toStringAsFixed(2));

            this.score = (roundedScore * 100).toInt();
          print('User Score : ${score}');
          breakdown = {
            "Braking": _ratingLabel(data['braking']),
            "Acceleration": _ratingLabel(data['acceleration']),
          };
        });
      } else {
        print('Failed to load score');
        setState(() {
          isLoading = false;
        });
      }


    final responsePrevTrips = await http.get(
        Uri.parse('$server/previoustrips'), 
        headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
        }
    );

    if (responsePrevTrips.statusCode == 200) {
        final data = json.decode(responsePrevTrips.body);
        //TODO 
    }
  }

  // loads a users scores and corresponding dates of a trip for graph
  Future<void> loadTripData() async {
  try {
    List<TripData> trips = await getPrevTripData();
    setState(() {
      scores = trips.map((t) => t.score).toList();
      dates = trips.map((t) => t.date).toList();
      isLoading = false;
    });
  } catch (e) {
    // handle error, show fallback UI or message
    setState(() {
      isLoading = false;
    });
  }
}


  // Will return different ratings depending on what final / metric score is given
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
    // If user doesn't have a score (error) direct them to start a trip
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : score == 0
            ? _buildNoTripsYet(context)
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Creates circle score with score percent in the middle
                    CircularPercentIndicator(
                      radius: screenHeight *.1, 
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
                    // Graph
                    MiniScoreGraph(
                      scores: convertScore(scores),   // Converts scores from 0-1 to 0-100 
                      height: screenHeight *.22,      // makes heigh of graph dynamic to size of screen
                      dates: dates
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.lightBlueAccent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      // Score Breakdown Container
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
                                _showFullReportModal(context);    // Method to expand description of individual driving habits
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.lightBlueAccent,
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
                  ],
                ),
              ),
    bottomNavigationBar: isLoading
        ? null
        // Creates bottom nav bar (role dependent)
        : CustomAppBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
            role: role,
          ).buildBottomNavBar(context),
  );
}

// Method to build View Full Report. Allows draggable scrollable sheet to view braking and acceleration
void _showFullReportModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.4, 
        minChildSize: 0.3,     
        maxChildSize: 0.9,    
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Full Driving Report",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
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
                        color: _ratingColor(entry.value),   // Returns 
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
    },
  );
}

  // Builds a page that directs user to start a trip if they have no trips recorded
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





  // Changes page depedning on what icon you click on bottom nav bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Creates color for score circle
  Color scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }


  // Used in View Full Report. Makes words correspond to colors
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

  List<double> convertScore(List<double> scores) {
    return scores.map((score) => score * 100).toList();
  }

  // Gets all trips scores and dates they were done on and puts it in a list to be used by the graph
  Future<List<TripData>> getPrevTripData () async {
    

    List<TripData> dateScoreList = [];    // list of all scores dates and associated scores
    
    List<Map<String, dynamic>> prevTripList = await TripService.fetchPreviousTripsData();   // list for previous trip structs
    
    // counter for testing
    int counter = 0;

    for (var prevTrip in prevTripList){
      counter++;
      // gets each scores score and start time
      double? score = prevTrip['trip_score'];
      String? date = prevTrip['start_time'];

      // used for testing date and score
      print(counter.toString() + ") score: " + score.toString() + "    date: " + date.toString());
      
      // If score and date are not null, add them to list
      //
      // update to use actual date
      if (/*date != null &&*/ score != null) { 
        dateScoreList.add(TripData(date: "date", score: score));
      }
        
    }

    print("Dates and Scores: "+dateScoreList.toList().toString());

    
    if (dateScoreList.isNotEmpty){
      return dateScoreList;
    }

    else {
      throw Exception('No valid trip data found.');
    }
      
  }
  

}

// Class to hold date and score to display on graph
class TripData {
  final String date;
  final double score;

  TripData({required this.date, required this.score});
} 
