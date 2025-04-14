import 'package:flutter/material.dart';

class UserLookupPage extends StatelessWidget {
  final Function(String) onSearch;
  final List<Map<String, dynamic>> searchResults;
  final bool isLoading;
  final String errorMessage;

  const UserLookupPage({
    required this.onSearch,
    required this.searchResults,
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
            labelText: 'Search by User ID, Name, or Email',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.search),
          ),
          onSubmitted: onSearch,
        ),
        SizedBox(height: 20),
        if (isLoading)
          Center(child: CircularProgressIndicator()),
        if (errorMessage.isNotEmpty)
          Text(errorMessage, style: TextStyle(color: Colors.red)),
        Expanded(
          child: ListView.builder(
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final user = searchResults[index];
              return Card(
                child: ListTile(
                  title: Text(user['name']),
                  subtitle: Text(user['email']),
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