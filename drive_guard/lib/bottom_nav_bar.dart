import 'package:flutter/material.dart';
import 'current_trip_page.dart';
import 'previous_trips_page.dart';
import 'score_page.dart';


// Will be used possibly in the future to make bottomnavigationbar load every pages body


class BottomNavBar extends StatefulWidget {
  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0; // Holds the index of the selected page

  final List<Widget> _pages = [
    Center(child: Text("Dashboard")), // Placeholder for Home Dashboard
    CurrentTripPage(),
    PreviousTripsPage(),
    ScorePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Updates selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: _pages[_selectedIndex], // Switch pages here
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped, // Handles tab clicks
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Current Trip'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline_outlined), label: 'Score'),
        ],
      ),
    );
  }
}