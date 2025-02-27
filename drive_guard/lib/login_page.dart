import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart';

class LoginPageWidget extends StatefulWidget {
  const LoginPageWidget({super.key});

  @override
  State<LoginPageWidget> createState() => _LoginPageWidgetState();
}

class _LoginPageWidgetState extends State<LoginPageWidget> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool isSignupMode = false; // Toggle between Login and Signup
  String? _selectedRole = 'User'; // Default role selection
  Map<String, TextEditingController> controllers = {
    'email': TextEditingController(),
    'first_name': TextEditingController(),
    'last_name': TextEditingController(),
    'password': TextEditingController(),
    'insurance_provider': TextEditingController(),
    'state': TextEditingController(),
    'server_number': TextEditingController(),
    'id': TextEditingController(),
  };
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _handleAuth(String url, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(role: _selectedRole!),
          ),
        );
      } else {
        final responseData = json.decode(response.body);
        _showErrorDialog(responseData['message']);
      }
    } catch (error) {
      _showErrorDialog('An error occurred. Please try again later.');
    }
  }

  Future<void> _signup() async {
    final String url = 'http://localhost:6969/signup';
    Map<String, dynamic> data = {
      'email': controllers['email']!.text,
      'password': controllers['password']!.text,
    };

    if (_selectedRole == 'User') {
      data.addAll({
        'first_name': controllers['first_name']!.text,
        'last_name': controllers['last_name']!.text,
      });
    } else if (_selectedRole == 'Service Provider') {
      data.addAll({
        'server_number': controllers['server_number']!.text,
        'id': controllers['id']!.text,
      });
    } else if (_selectedRole == 'Insurance Provider') {
      data.addAll({
        'insurance_provider_name': controllers['insurance_provider']!.text,
        'state': controllers['state']!.text,
        'id': controllers['id']!.text,
      });
    }

    _handleAuth(url, data);
  }

  Future<void> _login() async {
    final String url = 'http://localhost:6969/login';
    Map<String, dynamic> data = {
      'email': controllers['email']!.text,
      'password': controllers['password']!.text,
    };

    if (_selectedRole == 'Service Provider') {
      data.addAll({
        'server_number': controllers['server_number']!.text,
        'id': controllers['id']!.text,
      });
    } else if (_selectedRole == 'Insurance Provider') {
      data.addAll({
        'id': controllers['id']!.text,
        'insurance_provider_name': controllers['insurance_provider']!.text,
      });
    }

    _handleAuth(url, data);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _getRoleSpecificFields() {
    List<Widget> fields = [
      _buildTextField('Password', controllers['password']!, Icons.lock),
    ];

    if (_selectedRole == 'User') {
      fields.insertAll(0, [
        if (isSignupMode) _buildTextField('First Name', controllers['first_name']!, Icons.person),
        if (isSignupMode) _buildTextField('Last Name', controllers['last_name']!, Icons.person),
      ]);
    } else if (_selectedRole == 'Insurance Provider') {
      fields.insertAll(0, [
        if (isSignupMode) _buildTextField('Insurance Provider Name', controllers['insurance_provider']!, Icons.business),
        if (isSignupMode) _buildTextField('State', controllers['state']!, Icons.location_city),
      ]);
    } else if (_selectedRole == 'Service Provider') {
      fields.insertAll(0, [
        if (isSignupMode) _buildTextField('Server Number', controllers['server_number']!, Icons.computer),
      ]);
    }

    return Column(children: fields);
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData? icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
          hintText: 'Enter $label',
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          prefixIcon: icon != null ? Icon(icon, color: Colors.blue) : null, // Add icon here
        ),
        validator: (value) => value == null || value.isEmpty ? 'Please enter a valid $label' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [Colors.blue, Colors.pink],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Container(
                  width: screenWidth * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Text(
                              isSignupMode ? 'Create an Account' : 'Login to Your Account',
                              style: TextStyle(
                                fontSize: screenWidth * 0.08,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              'Welcome back! Please log in to continue.',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.05),
                      TabBar(
                        controller: _tabController,
                        tabs: [
                          Tab(child: Text('Sign In')),
                          Tab(child: Text('Sign Up')),
                        ],
                        onTap: (index) {
                          setState(() {
                            isSignupMode = index == 1;
                          });
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              items: [
                                DropdownMenuItem(value: 'User', child: Text('User')),
                                DropdownMenuItem(value: 'Insurance Provider', child: Text('Insurance Provider')),
                                DropdownMenuItem(value: 'Service Provider', child: Text('Service Provider')),
                              ],
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedRole = value;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Select Role',
                                labelStyle: TextStyle(color: Colors.blue),
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                              ),
                              validator: (value) => value == null ? 'Please select a role' : null,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            _buildTextField('Email', controllers['email']!, Icons.email),
                            _getRoleSpecificFields(),
                            SizedBox(height: screenHeight * 0.03),
                            Row(
                              children: [
                                SizedBox(
                                  width: screenWidth * 0.4,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState?.validate() ?? false) {
                                        if (isSignupMode) {
                                          _signup();  // Proceed to signup if form is valid
                                        } else {
                                          _login();  // Proceed to login if form is valid
                                        }
                                      } else {
                                        print("Form is not valid"); // For debugging purposes
                                      }
                                    },
                                    child: Text(isSignupMode ? 'Sign Up' : 'Login'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.black,
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 5,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(fontSize: 16, color: Colors.blue),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isSignupMode = !isSignupMode;
                          });
                        },
                        child: Text(
                          isSignupMode ? 'Already have an account? Log In' : 'Don\'t have an account? Sign Up',
                          style: TextStyle(color: Colors.blue, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
