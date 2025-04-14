import 'package:flutter/material.dart';

class UserTripsPage extends StatelessWidget {
  final String userId;
  final List<Map<String, dynamic>> trips;
  final bool isLoading;
  final String errorMessage;

  const UserTripsPage({
    required this.userId,
    required this.trips,
    required this.isLoading,
    required this.errorMessage,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Enter User ID',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {}, // Handle search
        ),
        SizedBox(height: 20),
        if (isLoading)
          Center(child: CircularProgressIndicator()),
        if (errorMessage.isNotEmpty)
          Text(errorMessage, style: TextStyle(color: Colors.red)),
        Expanded(
          child: trips.isEmpty
              ? Center(child: Text('No trips found'))
              : ListView.builder(
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return Card(
                      child: ListTile(
                        title: Text('Trip ${trip['id']}'),
                        subtitle: Text('${trip['distance']} miles'),
                        trailing: Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}