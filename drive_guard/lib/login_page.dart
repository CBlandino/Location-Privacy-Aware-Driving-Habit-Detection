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
  TextEditingController emailController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController insuranceProviderController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController serverNumberController = TextEditingController();
  TextEditingController idController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Function to handle signup
  Future<void> _signup() async {
    final String url = 'http://localhost:6969/signup'; // Use localhost with port 6969 for signup

    // Prepare the data for signup based on the selected role
    Map<String, dynamic> data = {
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
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
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
      _showErrorDialog('An error occurred. Please try again later.');
    }
  }

  // Function to handle login
  Future<void> _login() async {
    final String url = 'http://localhost:6969/login'; // Use localhost with port 6969 for login

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

      if (response.statusCode == 200) {
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
      _showErrorDialog('An error occurred. Please try again later.');
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
    // Get screen width and height using MediaQuery
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // Gradient background from bottom-left (blue) to top-right (magenta)
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [Colors.blue, Colors.pink], // Blue to Magenta
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Container(
                  width: screenWidth * 0.8, // Make container width responsive (80% of screen width)
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
                      // Header with Welcome Message
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Text(
                              isSignupMode ? 'Create an Account' : 'Login to Your Account',
                              style: TextStyle(
                                fontSize: screenWidth * 0.08, // Font size is responsive
                                fontWeight: FontWeight.bold,
                                color: Colors.black, // Black text for better contrast
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.02), // Responsive spacing
                            Text(
                              'Welcome back! Please log in to continue.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.05), // More responsive spacing
                      // TabBar for Login and Signup
                      TabBar(
                        controller: _tabController,
                        tabs: [
                          Tab(
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Tab(
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        onTap: (index) {
                          setState(() {
                            isSignupMode = index == 1;
                          });
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      // Form Start
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Role Selection Dropdown
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
                                labelStyle: TextStyle(
                                  color: Colors.blue,
                                ),
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                              ),
                              validator: (value) => value == null ? 'Please select a role' : null,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            // Email Field
                            TextFormField(
                              controller: emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(
                                  color: Colors.blue,
                                ),
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty || !value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            // Role-Specific Fields
                            _getRoleSpecificFields(),
                            SizedBox(height: screenHeight * 0.03),

                            // Row with Login and Forgot Password buttons
                            Row(
                              children: [
                                // Login Button (smaller)
                                SizedBox(
                                  width: screenWidth * 0.4, // Set a fixed width for the Login button
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
                                      style: TextStyle(fontSize: 18, color: Colors.black), // Black text
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue, // Same color for both buttons
                                      foregroundColor: Colors.black, // Black text
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 5,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10), // Space between buttons
                                
                                // Forgot Password Button (takes remaining space)
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
                      // Toggle between Login and Signup
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
            TextFormField(
              controller: firstNameController,
              decoration: InputDecoration(
                labelText: 'First Name',
                labelStyle: TextStyle(
                  color: Colors.blue,
                ),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Please enter your first name' : null,
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: lastNameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
                labelStyle: TextStyle(
                  color: Colors.blue,
                ),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Please enter your last name' : null,
            ),
            SizedBox(height: 20),
          ],
          TextFormField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(
                color: Colors.blue,
              ),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              return null;
            },
          ),
        ],
      );
    } else if (_selectedRole == 'Insurance Provider') {
      return Column(
        children: [
          if (isSignupMode) ...[
            TextFormField(
              controller: insuranceProviderController,
              decoration: InputDecoration(
                labelText: 'Insurance Provider Name',
                labelStyle: TextStyle(
                  color: Colors.blue,
                ),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Please enter the insurance provider name' : null,
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: stateController,
              decoration: InputDecoration(
                labelText: 'State',
                labelStyle: TextStyle(
                  color: Colors.blue,
                ),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Please enter your state' : null,
            ),
            SizedBox(height: 20),
          ],
          TextFormField(
            controller: idController,
            decoration: InputDecoration(
              labelText: 'ID',
              labelStyle: TextStyle(
                color: Colors.blue,
              ),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Please enter your ID' : null,
          ),
        ],
      );
    } else if (_selectedRole == 'Service Provider') {
      return Column(
        children: [
          if (isSignupMode) ...[
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(
                  color: Colors.blue,
                ),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
          ],
          TextFormField(
            controller: serverNumberController,
            decoration: InputDecoration(
              labelText: 'Server Number',
              labelStyle: TextStyle(
                color: Colors.blue,
              ),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty ? 'Please enter a server number' : null,
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: idController,
            decoration: InputDecoration(
              labelText: 'ID',
              labelStyle: TextStyle(
                color: Colors.blue,
              ),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Please enter your ID' : null,
          ),
        ],
      );
    }
    return SizedBox.shrink();
  }
}
