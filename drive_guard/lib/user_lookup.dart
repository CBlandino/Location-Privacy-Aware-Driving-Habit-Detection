import 'package:flutter/material.dart';

class UserLookupPage extends StatelessWidget {
  final Function(String) onSearch;
  final List<Map<String, dynamic>> searchResults;
  final bool isLoading;
  final String errorMessage;
  final String initialSearchQuery;

  const UserLookupPage({
    required this.onSearch,
    this.searchResults = const [],
    this.isLoading = false,
    this.errorMessage = '',
    this.initialSearchQuery = '',
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController _searchController = 
        TextEditingController(text: initialSearchQuery);

    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search Users',
            hintText: 'Enter name, email, or ID',
            border: OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(Icons.search),
              onPressed: () => onSearch(_searchController.text.trim()),
            ),
          ),
          onSubmitted: (query) => onSearch(query.trim()),
        ),
        SizedBox(height: 20),
        
        if (isLoading)
          Center(child: CircularProgressIndicator()),
        
        if (errorMessage.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        
        if (!isLoading && errorMessage.isEmpty)
          Expanded(
            child: _buildResultsContent(),
          ),
      ],
    );
  }

  Widget _buildResultsContent() {
    if (initialSearchQuery.isEmpty && searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search for users by name, email, or ID',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (searchResults.isEmpty && initialSearchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No users found matching "$initialSearchQuery"',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final user = searchResults[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(user['name']?.substring(0, 1) ?? '?'),
            ),
            title: Text(user['name'] ?? 'Unknown User'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['email'] ?? 'No email'),
                if (user['id'] != null) 
                  Text('ID: ${user['id']}', 
                      style: TextStyle(fontSize: 12)),
              ],
            ),
            trailing: Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}