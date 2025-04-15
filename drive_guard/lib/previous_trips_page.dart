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
  String? _filter;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    fetchPreviousTrips();
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    role = prefs.getString('role')!;
    setState(() => isLoading = false);
  }

  Future<void> fetchPreviousTrips() async {
    setState(() => isLoading = true);
    List<dynamic> data = await TripService.fetchPreviousTrips();
    if (mounted) {
      setState(() {
        trips = data;
        _sortTrips();
        isLoading = false;
      });
    }
  }

  void _sortTrips() {
    if (_filter == 'recent') {
      trips.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    } else if (_filter == 'longest') {
      trips.sort((a, b) => b['distance'].compareTo(a['distance']));
    }
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blue[800]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        )),
        Text(value, style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        )),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

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
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchPreviousTrips,
              child: trips.isEmpty
                  ? Center(
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
                              // Navigate to trip start page
                            },
                            child: const Text("Start a new trip"),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Your Trips",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              FilterChip(
                                label: Text("Recent", style: TextStyle(
                                  color: _filter == 'recent' ? Colors.white : Colors.blue[800],
                                )),
                                selected: _filter == 'recent',
                                selectedColor: Colors.blue[800],
                                backgroundColor: Colors.white,
                                shape: StadiumBorder(
                                  side: BorderSide(color: Colors.blue[800]!)
                                ),
                                onSelected: (bool selected) {
                                  setState(() {
                                    _filter = selected ? 'recent' : null;
                                    _sortTrips();
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: Text("Longest", style: TextStyle(
                                  color: _filter == 'longest' ? Colors.white : Colors.blue[800],
                                )),
                                selected: _filter == 'longest',
                                selectedColor: Colors.blue[800],
                                backgroundColor: Colors.white,
                                shape: StadiumBorder(
                                  side: BorderSide(color: Colors.blue[800]!)
                                ),
                                onSelected: (bool selected) {
                                  setState(() {
                                    _filter = selected ? 'longest' : null;
                                    _sortTrips();
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(Icons.timeline, "Total Miles",
                                    "${TripService.calculateTotalDistance(trips).toStringAsFixed(1)} mi"),
                                _buildStatItem(Icons.directions_car, "Trips",
                                    "${trips.length}"),
                                _buildStatItem(Icons.av_timer, "Avg. Time",
                                    "${TripService.calculateAvgTime(trips)} min"),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView.separated(
                              itemCount: trips.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final trip = trips[index];
                                final timestamp = trip['timestamp'] is int
                                    ? trip['timestamp']
                                    : DateTime.parse(trip['timestamp']).millisecondsSinceEpoch ~/ 1000;
                                final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

                                return Card(
                                  elevation: 2,
                                  color: Colors.white,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.blue[100]!),
                                      ),
                                      child: Icon(
                                        Icons.directions_car,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                    title: Text(
                                      DateFormat('MMM dd, yyyy').format(date),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "${trip['distance']?.toStringAsFixed(2) ?? '0.00'} miles • ${DateFormat('hh:mm a').format(date)}",
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: Colors.blue[800],
                                    ),
                                    onTap: () => TripService.showTripDetails(context, trip),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
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