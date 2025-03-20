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
    int _selectedIndex = 0;

    final List<Widget> _pages = [
      // HomePage(),      // Home Dashboard
      CurrentTripPage(),    // Current Trip
      PreviousTripsPage(),  // Previous Trips
      ScorePage(),          // Score Page
    ];

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index; // Switches pages     
      });
    }


  List<dynamic> trips = [];
  bool isLoading = true;
  String errorMessage = '';

  Future<void> _loadTrips() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8080/trips'));
      if (response.statusCode == 200) {
        setState(() {
          trips = json.decode(response.body);
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
    _loadTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      drawer: CustomDrawer(role: widget.role),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[400],
                  child: Text(
                    'JD', // Replace with user's initials dynamically
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Welcome to Your Dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'John Doe!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              SizedBox(height: 60),
              Center(
                child: Container(
                  padding: EdgeInsets.all(10),      
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.grey.shade400, blurRadius: 15, spreadRadius: 2)],
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: [0.0 , 0.5, 1.0],
                      colors: [Colors.white, Colors.white, Colors.grey.shade300]
                    )  
                  ),
                  child: RawMaterialButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CurrentTripPage()),
                      );
                    },
                    shape: CircleBorder(),
                    elevation: 2.0,
                    fillColor: Colors.white,
                    padding: const EdgeInsets.all(85.0),

                    child: Text(
                      "Start Trip",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 60),
              // SizedBox(height: 30),
              // _buildSection(
              //   title: 'Start New Trip',
              //   icon: Icons.directions_car,
              //   buttonText: 'Start Trip',
              //   description: 'Tap to begin a new trip and track your progress.',
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => CurrentTripPage(),
              //       ),
              //     );
              //   },
              // ),
              Container(
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 30),
                    _buildPreviousTripsSection(),
                    SizedBox(height: 30),
                    _buildSection(
                      title: 'Score',
                      icon: Icons.star,
                      buttonText: 'Check Score',
                      //description: 'View your trip completion score and progress.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScorePage(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        elevation: 10,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Current Trip'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Previous Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline_outlined), label: 'Score'),
        ],
        /*onTap: (index) {
          switch (index) {
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CurrentTripPage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PreviousTripsPage()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ScorePage()),
              );
              break;
          }
        },*/
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required String buttonText,
    String? description,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 10,
      color: Colors.blue.withOpacity(.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            if (description != null)
              SizedBox(height: 10),
            if (description != null)
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

  

  Widget _buildPreviousTripsSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 10,
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
                              trips.length > 3 ? 3 : trips.length,
                              (index) {
                                var trip = trips[index];
                                return ListTile(
                                  tileColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  title: Text('Trip ${trip['id']}'),
                                  subtitle: Text('Duration: ${trip['duration']} minutes\nDate: ${trip['date']}'),
                                  trailing: Icon(Icons.arrow_forward),
                                  onTap: () {},
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
