import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'custom_app_bar.dart';
import 'user_home_page.dart';
import 'insurance_home_page.dart';
import 'admin_home_page.dart';

class HomePage extends StatefulWidget {
  final String role;

  const HomePage({Key? key, required this.role}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  File? _profileImage;
  bool isLoading = true;
  late String role;
  late String email;
  late String firstName;
  late String lastName;

  @override
  void initState() {
    super.initState();
    _checkAuthToken();
    _loadProfileImage();
  }

  Future<void> _checkAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token != null) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      setState(() {
        role = decodedToken['role'];
        firstName = decodedToken['first_name'];
        lastName = decodedToken['last_name'];
        email = decodedToken['email'];
        isLoading = false;
      });

      await prefs.setString('role', role);
      await prefs.setString('first_name', firstName);
      await prefs.setString('last_name', lastName);
      await prefs.setString('email', email);
    } else {
      debugPrint('No token found in SharedPreferences');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image');
    if (imagePath != null) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildRoleSpecificHomePage(bool isWeb) {
    switch (widget.role) {
      case 'user':
        return UserHomePage(
          firstName: firstName,
          lastName: lastName,
          profileImage: _profileImage,
        );
      case 'insurance':
        return const InsuranceHomePage();
      case 'admin':
        return const AdminHomePage();
      default:
        return const Center(child: Text('Unknown role'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final maxWidth = isWeb ? 1200.0 : double.infinity;
    final isAdminOrInsurance = widget.role == 'admin' || widget.role == 'insurance';

    return Scaffold(
      appBar: isLoading
          ? null
          : CustomAppBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
              role: widget.role,
            ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: _buildRoleSpecificHomePage(isWeb),
              ),
            ),
      bottomNavigationBar: isLoading || (isWeb && isAdminOrInsurance)
          ? null
          : CustomAppBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
              role: widget.role,
            ).buildBottomNavBar(context),
    );
  }
}