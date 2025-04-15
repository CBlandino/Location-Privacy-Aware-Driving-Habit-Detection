import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'custom_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'trip_helper.dart';

class PreviousTripsPage extends StatefulWidget {
  @override
  _PreviousTripsPageState createState() => _PreviousTripsPageState();
}

class _PreviousTripsPageState extends State<PreviousTripsPage> {
  List<dynamic> trips = [];
  late String role;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    fetchPreviousTrips();
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    role = prefs.getString('role')!;
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchPreviousTrips() async {
    List<dynamic> data = await TripService.fetchPreviousTrips();
    if (mounted) {
      setState(() {
        trips = data;
      });
    }
  }

void _showTripDetails(Map<String, dynamic> trip) {
  int timestamp;
  
  try {
    timestamp = trip['timestamp'] is int
        ? trip['timestamp']
        : DateTime.parse(trip['timestamp']).millisecondsSinceEpoch ~/ 1000;
  } catch (e) {
    print('Error parsing timestamp: $e');
    timestamp = 0;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
        title: Text("Trip Details", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.calendar_today, "Date:", 
                  timestamp > 0 ? DateFormat('MMM dd, yyyy').format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)) : 'N/A'),
              _buildDetailRow(Icons.access_time, "Time:", 
                  timestamp > 0 ? DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)) : 'N/A'),
              _buildDetailRow(Icons.directions_car, "Distance:", 
                  "${trip['distance']?.toStringAsFixed(2) ?? 'N/A'} miles"),
              _buildDetailRow(Icons.speed, "Average Speed:", 
                  "${trip['velocity']?.toStringAsFixed(1) ?? 'N/A'} mph"),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Close", style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      );
    },
  );
}

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 10),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 5),
          Text(value),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  int _selectedIndex = 1;

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: isLoading
        ? null
        : CustomAppBar(
            selectedIndex: 1,
            onItemTapped: _onItemTapped,
            role: role,
          ),
    body: isLoading
        ? Center(
            child: CircularProgressIndicator(), 
          )
        : trips.isEmpty
            ? Center(
                child: Column( 
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      "No trips recorded yet",
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Your trips will appear here after completion",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column( // Fixed child parameter here
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Trips",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated( // Fixed child parameter here
                        itemCount: trips.length,
                        separatorBuilder: (context, index) => Divider(height: 1),
                        itemBuilder: (context, index) {
                          final trip = trips[index];
                          final timestamp = trip['timestamp'] is int
                              ? trip['timestamp']
                              : DateTime.parse(trip['timestamp']).millisecondsSinceEpoch ~/ 1000;
                          final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
                          
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.directions_car,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              title: Text(
                                DateFormat('MMM dd, yyyy').format(date),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "${trip['distance']?.toStringAsFixed(2) ?? '0.00'} miles • ${DateFormat('hh:mm a').format(date)}",
                              ),
                              trailing: Icon(Icons.chevron_right),
                              onTap: () => _showTripDetails(trip),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    bottomNavigationBar: isLoading
        ? null
        : CustomAppBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
            role: role,
          ).buildBottomNavBar(context),
  );
}
}