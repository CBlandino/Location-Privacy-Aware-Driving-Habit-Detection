import 'dart:io';

import 'package:flutter/material.dart';
import 'current_trip_page.dart';
import 'trip_helper.dart';

class UserHomePage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final File? profileImage;

  const UserHomePage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.profileImage,
  });

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  List<dynamic> recentTrips = [];
  String errorMessage = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecentTrips();
  }

  Future<void> _loadRecentTrips() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      List<dynamic> trips = await TripService.fetchPreviousTrips();
      setState(() {
        recentTrips = trips.take(3).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load recent trips';
      });
    }
  }

  Widget _buildPreviousTripsSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.lightBlueAccent,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Trips',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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
                    : recentTrips.isEmpty
                        ? Center(
                            child: Text(
                              'No recent trips available.',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          )
                        : Column(
                            children: recentTrips.take(3).map((trip) {
                               
                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[700],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.directions_car,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    TripService.formatTimestamp(trip['start_time'] ?? trip['timestamp']),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text( 
                                    '${trip['distance']?.toStringAsFixed(2) ?? '0.00'} miles',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(204),
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.chevron_right,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      TripService.showTripDetails(context, trip);
                                    },
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayName = '${widget.firstName} ${widget.lastName}';
    String initials = (widget.firstName.isNotEmpty && widget.lastName.isNotEmpty)
        ? '${widget.firstName[0]}${widget.lastName[0]}'.toUpperCase()
        : '??';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with welcome and profile
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.shade300,
                    backgroundImage: widget.profileImage != null 
                        ? FileImage(widget.profileImage!) 
                        : null,
                    child: widget.profileImage == null
                        ? Text(
                            initials,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Start Trip Button
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CurrentTripPage()),
                  );
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blue.shade700, Colors.blue.shade400],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(102),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 48,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Start Trip",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),

            // Recent Trips Section
            Text(
              'Recent Trips',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 16),
            _buildPreviousTripsSection(),
            SizedBox(height: 24),

            // Score Section
            Text(
              'Your Safety Score',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                // Navigate to score page
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.blue.shade50, Colors.white],
                  ),
                  border: Border.all(color: Colors.blue.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 40, color: Colors.amber),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'View your score',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Check your latest driving safety assessment',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.blue.shade400),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}