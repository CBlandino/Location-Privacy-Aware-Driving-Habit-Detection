import 'package:flutter/material.dart';

import 'custom_app_bar.dart';

class UserLookupPage extends StatefulWidget {
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
  _UserLookupPageState createState() => _UserLookupPageState();
}

class _UserLookupPageState extends State<UserLookupPage> {
  int _selectedIndex = 0;

  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearchQuery;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigation will be handled by CustomAppBar's _navigateToPage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        role: 'insurance',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Users',
                hintText: 'Enter name, email, or ID',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => widget.onSearch(_searchController.text.trim()),
                ),
              ),
              onSubmitted: (query) => widget.onSearch(query.trim()),
            ),
            SizedBox(height: 20),
            if (widget.isLoading)
              Expanded(child: Center(child: CircularProgressIndicator())),
            if (widget.errorMessage.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  widget.errorMessage,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            if (!widget.isLoading && widget.errorMessage.isEmpty)
              Expanded(child: _buildResultsContent(widget.initialSearchQuery, widget.searchResults)),
          ],
        ),
      ),
      bottomNavigationBar: CustomAppBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        role: 'insurance',
      ).buildBottomNavBar(context),
    );
  }

  Widget _buildResultsContent(dynamic initialSearchQuery, dynamic searchResults) {
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