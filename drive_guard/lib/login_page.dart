import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  TextEditingController emailController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController insuranceProviderController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController serverNumberController = TextEditingController();
  TextEditingController idController = TextEditingController();
  late TabController _tabController;

  final String server = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Function to handle signup
  Future<void> _signup() async {
    final String url = '$server/signup'; // Use 10.0.2.2 to connect to the host machine

    // Prepare the data for signup based on the selected role
    Map<String, dynamic> data = 
    {
      'email': emailController.text,
      'password': passwordController.text,
    };

    if (_selectedRole == 'User') {
      data['first_name'] = firstNameController.text;
      data['last_name'] = lastNameController.text;
    } else if (_selectedRole == 'Service Provider') {
      data['server_number'] = serverNumberController.text;
      data['id'] = idController.text;
    } else if (_selectedRole == 'Insurance Provider') {
      data['insurance_provider_name'] = insuranceProviderController.text;
      data['state'] = stateController.text;
      data['id'] = idController.text;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {

        final responseData = json.decode(response.body);
        String token = responseData['access_token'];

        // Save token for authentication
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        //await prefs.setString('user_name', userName ?? 'Unknown User');
        //await prefs.setString('user_email', userEmail ?? 'No Email');

        // Success: Navigate to home page or show success message
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(role: _selectedRole!),
          ),
        );
      } else {
        // Error: Show error message
        final responseData = json.decode(response.body);
        _showErrorDialog(responseData['message']);
      }
    } catch (error) {
       _showErrorDialog('Error: $error');
      _showErrorDialog('An error occurred. Please try again later.');
    }
  }

  // Function to handle login
  Future<void> _login() async {
    final String url = '$server/login'; // use 10.0.2.2 to connect to the host machine

    Map<String, dynamic> data = {
      'email': emailController.text,
      'password': passwordController.text,
    };

    if (_selectedRole == 'Service Provider') {
      data['server_number'] = serverNumberController.text;
      data['id'] = idController.text;
    } else if (_selectedRole == 'Insurance Provider') {
      data['id'] = idController.text;
      data['insurance_provider_name'] = insuranceProviderController.text;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      

      if (response.statusCode == 202) {
        final responseData = json.decode(response.body);

       //print('ResponseData Token : ${responseData['token']}');
       String token = responseData['access_token'];

       // Save token to shared preferences
       SharedPreferences prefs = await SharedPreferences.getInstance();
       await prefs.setString('auth_token', token);

        // Success: Navigate to home page or show success message
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(role: _selectedRole!),
          ),
        );
      } else {
        // Error: Show error message
        final responseData = json.decode(response.body);
        _showErrorDialog(responseData['message']);
      }
    } catch (error) {
       _showErrorDialog('Error: $error');
      _showErrorDialog('The Server is down. Please try again later.');
    }
  }

  // Function to show error dialog
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
                          Tab(child: Text('Log In')),
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
                            _buildTextField('Email', emailController, Icons.email),
                            _getRoleSpecificFields(),
                            SizedBox(height: screenHeight * 0.03),
                            Row(
                              children: [
                                SizedBox(
                                  width: screenWidth * 0.4,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        if (isSignupMode) {
                                          _signup();
                                        } else {
                                          _login();
                                        }
                                      }
                                    },
                                    child: Text(
                                      isSignupMode ? 'Sign Up' : 'Login',
                                      style: TextStyle(fontSize: 18, color: Colors.black),
                                    ),
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
                                    onPressed: () {
                                      // Handle Forgot Password action here
                                    },
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

  // Function to Show Role-Specific Fields
  Widget _getRoleSpecificFields() {
    if (_selectedRole == 'User') {
      return Column(
        children: [
          if (isSignupMode) ...[
            _buildTextField('First Name', firstNameController, Icons.person),
            SizedBox(height: 20),
            _buildTextField('Last Name', lastNameController, Icons.person),
            SizedBox(height: 20),
          ],
          _buildTextField('Password', passwordController, Icons.lock),
        ],
      );
    } else if (_selectedRole == 'Insurance Provider') {
      return Column(
        children: [
          if (isSignupMode) ...[
            _buildTextField('Insurance Provider Name', insuranceProviderController, Icons.business),
            SizedBox(height: 20),
            _buildTextField('State', stateController, Icons.location_city),
            SizedBox(height: 20),
          ],
          _buildTextField('ID', idController, Icons.card_membership),
        ],
      );
    } else if (_selectedRole == 'Service Provider') {
      return Column(
        children: [
          if (isSignupMode) ...[
            _buildTextField('Email', emailController, Icons.email),
            SizedBox(height: 20),
          ],
          _buildTextField('Server Number', serverNumberController, Icons.computer),
          SizedBox(height: 20),
          _buildTextField('ID', idController, Icons.card_membership),
        ],
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blue),
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a valid $label';
          }
          return null;
        },
      ),
    );
  }
}