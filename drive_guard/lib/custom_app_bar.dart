import 'package:flutter/material.dart';

import 'current_trip_page.dart';
import 'previous_trips_page.dart';
import 'score_page.dart';
import 'settings_page.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomAppBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(_getAppBarTitle(selectedIndex)),
      centerTitle: true,
      backgroundColor: Colors.blue,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return "Home";
      case 1:
        return "Previous Trips";
      case 2:
        return "Score";
      case 3:
        return "Account";
      default:
        return "Home";
    }
  }

  Widget buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      elevation: 10,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        onItemTapped(index); // Update selected index
        _navigateToPage(context, index); // Handle navigation
      },
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Current Trip'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Previous Trips'),
        BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Score'),
        BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
      ],
    );
  }

  void _navigateToPage(BuildContext context, int index) {
    Widget page;
    switch (index) {
      case 0:
        page = CurrentTripPage();
        break;
      case 1:
        page = PreviousTripsPage();
        break;
      case 2:
        page = ScorePage();
        break;
      case 3:
        page = SettingsPage();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
