import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'home_page.dart';
import 'ipconfig.dart';

class LoginPageWidget extends StatefulWidget {
  const LoginPageWidget({super.key});

  @override
  State<LoginPageWidget> createState() => _LoginPageWidgetState();
}

class _LoginPageWidgetState extends State<LoginPageWidget>
  with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late SharedPreferences _prefs;
  bool isSignupMode = false;
  bool _isProcessing = false;
  String? _selectedRole = 'User';

  TextEditingController emailController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController insuranceProviderController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController serverNumberController = TextEditingController();
  TextEditingController idController = TextEditingController();
  late TabController _tabController;

  final String server = AppConfig.server;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _prefs = prefs;
      });
    });
  }

  //   @override
  // void dispose() {
  //   emailController.dispose();
  //   passwordController.dispose();
  //   lastNameController.dispose();
  //   passwordController.dispose();
  //   insuranceProviderController.dispose();
  //   stateController.dispose();
  //   serverNumberController.dispose();
  //   idController.dispose();

  //   super.dispose();
  // }

  Future<Map<String, dynamic>> parseJson(String responseBody) async {
    await Future.delayed(Duration(milliseconds: 100));
    return compute(json.decode(responseBody), responseBody);
  }

  // Function to handle signup
  Future<void> _signup() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final String url = '$server/signup'; // Use 10.0.2.2 to connect to the host machine

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

        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        );

        if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        await _prefs.setString('access_token', responseData['access_token']);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(role: _selectedRole!)),
        );
        } else {
          final responseData = await parseJson(response.body);
          _showErrorDialog(responseData['message']);
        }
    } catch (error) {
      _showErrorDialog('An error occurred. Please try again later.');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // Function to handle login
  Future<void> _login() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
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

        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        );

        if (response.statusCode == 202) {
        final responseData = json.decode(response.body);
        await _prefs.setString('access_token', responseData['access_token']);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(role: _selectedRole!)),
        );
        } else {
          // Error: Show error message
          final responseData = await parseJson(response.body);
          _showErrorDialog(responseData['message']);
        }
    } catch (error) {
      _showErrorDialog('The Server is down. Please try again later.');
    } finally {
      setState(() => _isProcessing = false);
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Container(
                width: screenWidth * 0.8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                            isSignupMode
                                ? 'Create an Account'
                                : 'Login to Your Account',
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
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
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
                        indicatorColor: Colors.blue, 
                        labelColor: Colors.blue, 
                        unselectedLabelColor: Colors.grey,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            items: [
                              DropdownMenuItem(
                                value: 'User',
                                child: Text('User'),
                              ),
                              DropdownMenuItem(
                                value: 'Insurance Provider',
                                child: Text('Insurance Provider'),
                              ),
                              DropdownMenuItem(
                                value: 'Service Provider',
                                child: Text('Service Provider'),
                              ),
                            ],
                            onChanged: (String? value) {
                              setState(() {
                                _selectedRole = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Select Role',
                              labelStyle: TextStyle(color: Colors.blue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                              ),
                            ),
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Please select a role'
                                        : null,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          _buildTextField(
                            'Email',
                            emailController,
                            Icons.email,
                          ),
                          _getRoleSpecificFields(),
                          SizedBox(height: screenHeight * 0.03),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: screenWidth * 0.6,
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
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.black,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    textStyle: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    elevation: 5,
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
                        isSignupMode
                            ? 'Already have an account? Log In'
                            : 'Don\'t have an account? Sign Up',
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
    );
  }

  // Function to Show Role-Specific Fields
  Widget _getRoleSpecificFields() {
    final screenHeight = MediaQuery.of(context).size.height;

    if (_selectedRole == 'User') {
      return Column(
        children: [
          if (isSignupMode) ...[
            _buildTextField('First Name', firstNameController, Icons.person),
            _buildTextField('Last Name', lastNameController, Icons.person),
          ],
          _buildTextField('Password', passwordController, Icons.lock),
        ],
      );
    } else if (_selectedRole == 'Insurance Provider') {
      return Column(
        children: [
          if (isSignupMode) ...[
            _buildTextField(
              'Insurance Provider Name',
              insuranceProviderController,
              Icons.business,
            ),
            _buildTextField('State', stateController, Icons.location_city),
          ],
          _buildTextField('ID', idController, Icons.card_membership),
        ],
      );
    } else if (_selectedRole == 'Service Provider') {
      return Column(
        children: [
          if (isSignupMode) ...[
            _buildTextField('Email', emailController, Icons.email),
          ],
          _buildTextField(
            'Server Number',
            serverNumberController,
            Icons.computer,
          ),
          _buildTextField('ID', idController, Icons.card_membership),
        ],
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blue),
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(22)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
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

// place right below inouts, but aboce login/signup button
// Expanded(
//   child: TextButton(
//     onPressed: () {
//       // Handle Forgot Password action here
//     },
//     child: Text(
//       'Forgot Password?',
//       style: TextStyle(fontSize: 16, color: Colors.blue),
//     ),
//   ),
// ),
