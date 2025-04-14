import 'package:flutter/material.dart';

class UserTripsPage extends StatelessWidget {
  final String userId;
  final List<Map<String, dynamic>> trips;
  final bool isLoading;
  final String errorMessage;
  final Function(String)? onSearchSubmitted;

  const UserTripsPage({
    this.userId = '', // Default empty string
    this.trips = const [], // Default empty list
    this.isLoading = false,
    this.errorMessage = '',
    this.onSearchSubmitted,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
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
          Expanded(
            child: _buildTripsContent(),
          ),
      ],
    );
  }

  Widget _buildTripsContent() {
    if (userId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Enter a User ID to search for trips',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No trips found for this user',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
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