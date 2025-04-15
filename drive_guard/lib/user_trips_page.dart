import 'package:flutter/material.dart';

class UserTripsPage extends StatelessWidget {
  final String userId;
  final List<Map<String, dynamic>> trips;
  final bool isLoading;
  final String errorMessage;
  final Function(String)? onSearchSubmitted;

  const UserTripsPage({
    this.userId = '',
    this.trips = const [],
    this.isLoading = false,
    this.errorMessage = '',
    this.onSearchSubmitted,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Trips')),
      body: Padding(
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
              onSubmitted: onSearchSubmitted,
              controller: TextEditingController(text: userId),
            ),
            SizedBox(height: 20),

            if (isLoading)
              Center(child: CircularProgressIndicator()),

            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            if (!isLoading && errorMessage.isEmpty)
              Expanded(child: _buildTripsContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsContent() {
    if (userId.isEmpty) {
      return _buildMessage("Enter a User ID to search for trips", Icons.search);
    }

    if (trips.isEmpty) {
      return _buildMessage("No trips found for this user", Icons.directions_car);
    }

    return ListView.builder(
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ListTile(
            leading: Icon(Icons.trip_origin, color: Colors.blue),
            title: Text('Trip on ${_formatDate(trip['start_time'])}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Distance: ${trip['distance']?.toStringAsFixed(2) ?? 'N/A'} miles'),
                Text('Duration: ${_formatDuration(trip['duration'])}'),
              ],
            ),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Handle trip tap if needed
            },
          ),
        );
      },
    );
  }

  Widget _buildMessage(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return 'Unknown date';
    try {
      final date = DateTime.parse(timestamp);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return 'N/A';
    final duration = Duration(seconds: seconds);
    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
  }
}
