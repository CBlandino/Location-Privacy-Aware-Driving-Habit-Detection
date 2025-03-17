import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'custom_drawer.dart'; // Import CustomDrawer
import 'current_trip_page.dart'; // For navigation to CurrentTripPage
import 'previous_trips_page.dart';
import 'score_page.dart';

class HomePage extends StatefulWidget {
  final String role;

  HomePage({required this.role});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> trips = [];
  bool isLoading = true;
  String errorMessage = ''; // Variable to store the error message
  
  // Simulate a function to load trips from the server
  Future<void> _loadTrips() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8080/trips')); // Replace with your server URL
      
      if (response.statusCode == 200) {
        setState(() {
          trips = json.decode(response.body); // Assuming the response is a JSON array
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load trips. Please try again later.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading trips: $e';
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTrips(); // Load trips when the page is loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      drawer: CustomDrawer(role: widget.role), // Add CustomDrawer
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header for the page
              Text(
                'Welcome to Your Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 30),

              // Start Trip Section
              _buildSection(
                title: 'Start New Trip',
                icon: Icons.directions_car,
                buttonText: 'Start Trip',
                description: 'Tap to begin a new trip and track your progress.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CurrentTripPage(),
                    ),
                  );
                },
              ),
              SizedBox(height: 30), // Increased spacing between sections

              // Previous Trips Section (Improved card with last 3 trips)
              _buildPreviousTripsSection(),
              SizedBox(height: 30), // Increased spacing between sections

              // Score Section (Add Score logic here)
              _buildSection(
                title: 'Score',
                icon: Icons.star,
                buttonText: 'Check Score',
                description: 'View your trip completion score and progress.',
                onTap: () {
                  // Navigate to Score page or display score-related information
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScorePage(), // Replace with your score page
                    ),
                  );
                },
              ),
              SizedBox(height: 30), // Increased spacing between sections
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build the sections (Start Trip, Previous Trips, Score)
  Widget _buildSection({
    required String title,
    required IconData icon,
    required String buttonText,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 10,
      margin: EdgeInsets.symmetric(vertical: 10),
      color: Colors.blueAccent,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.all(0),
              leading: Icon(icon, color: Colors.white, size: 40),
              title: Text(
                title,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              trailing: ElevatedButton(
                onPressed: onTap,
                child: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10), // Space between title and description
            Text(
              description,
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Build the Previous Trips Section with the last 3 trips
  Widget _buildPreviousTripsSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 10,
      margin: EdgeInsets.symmetric(vertical: 10),
      color: Colors.lightBlueAccent,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Previous Trips',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 10),
            // Show loading indicator or error message for trips
            isLoading
                ? Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Text(
                          errorMessage,
                          style: TextStyle(color: Colors.red, fontSize: 18),
                        ),
                      )
                    : trips.isEmpty
                        ? Center(
                            child: Text(
                              'No previous trips available.',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          )
                        : Column(
                            children: List.generate(
                              trips.length > 3 ? 3 : trips.length, // Display up to 3 trips
                              (index) {
                                var trip = trips[index];
                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                  color: Colors.white,
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                                    title: Text(
                                      'Trip ${trip['id']}',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      'Duration: ${trip['duration']} minutes\nDate: ${trip['date']}',
                                      style: TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                    trailing: Icon(Icons.arrow_forward),
                                    onTap: () {
                                      // Navigate to Trip Details or Current Trip
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CurrentTripPage(),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ],
        ),
      ),
    );
  }
}
