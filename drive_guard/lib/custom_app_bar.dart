import 'package:flutter/material.dart';

import 'current_trip_page.dart';
import 'previous_trips_page.dart';
import 'score_page.dart';
import 'settings_page.dart';
import 'user_lookup.dart';
import 'user_score_page.dart';
import 'user_trips_page.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final String? role;

  const CustomAppBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.role,
  }) : super(key: key);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  late String role;

 @override
  void initState() {
    super.initState();
    role = widget.role!; // default if null
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(_getAppBarTitle(widget.selectedIndex)),
      centerTitle: true,
      backgroundColor: Colors.blue,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  String _getAppBarTitle(int index) {
    if (role == 'insurance') {
      switch (index) {
        case 0: return "User Lookup";
        case 1: return "User Trips";
        case 2: return "User Scores";
        case 3: return "Account";
        default: return "User Lookup";
      }
    } else if(role == 'user') { // User role
      switch (index) {
        case 0: return "Home";
        case 1: return "Previous Trips";
        case 2: return "Score";
        case 3: return "Account";
        default: return "Home";
      }
    }
    else 
    {
      switch (index) {
        case 0: return "Home";
        case 1: return "Previous Trips";
        case 2: return "Score";
        case 3: return "Account";
        default: return "Home";
      }
    }
  }


  Widget buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.selectedIndex,
      elevation: 10,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        widget.onItemTapped(index); // Update selected index
        _navigateToPage(context, index); // Handle navigation
      },
      items: role == 'Insurance Provider' 
          ? _buildInsuranceNavItems()
          : _buildUserNavItems(),
    );
  }

  List<BottomNavigationBarItem> _buildInsuranceNavItems() {
    return [
      BottomNavigationBarItem(
        icon: Icon(Icons.person_search),
        label: 'Lookup',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: 'Trips',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.score),
        label: 'Scores',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.account_circle),
        label: 'Account',
      ),
    ];
  }

  List<BottomNavigationBarItem> _buildUserNavItems() {
    return [
      BottomNavigationBarItem(
        icon: Icon(Icons.directions_car),
        label: 'Current Trip',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: 'Previous Trips',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.star),
        label: 'Score',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.account_circle),
        label: 'Account',
      ),
    ];
  }

  void _navigateToPage(BuildContext context, int index) {
    Widget page;
    
    if (role == 'Insurance Provider') {
      switch (index) {
        case 0:
          page = UserLookupPage(
            onSearch: (query) {}, 
            searchResults: [],
            isLoading: false,
            errorMessage: '',
          );
          break;
        case 1:
          page = UserTripsPage(
            userId: '',
            trips: [],
            isLoading: false,
            errorMessage: '',
          );
          break;
        case 2:
          page = UserScorePage(
            userId: '',
            scoreData: null,
            isLoading: false,
            errorMessage: '',
          );
          break;
        case 3:
          page = SettingsPage();
          break;
        default:
          return;
      }
    } else {
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
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
