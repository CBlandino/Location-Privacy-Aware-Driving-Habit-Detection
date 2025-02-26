import 'package:flutter/material.dart';
import 'home_page.dart';

// Login page where users authenticate.
// Future Enhancements:
// - Implement authentication API calls
// - Add Remember Me functionality
// - Improve input validation and error handling
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  String? _selectedRole = 'User'; // Selected user role during login
  TextEditingController emailController = TextEditingController(); // Stores user input
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController insuranceProviderController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController serverNumberController = TextEditingController();
  TextEditingController idController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Login to Your Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333), // Dark text
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
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
                      labelStyle: TextStyle(color: Color(0xFF333333)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Color(0xFFEBEBEB),
                    ),
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a role';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Color(0xFF333333)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Color(0xFFEBEBEB),
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
                  // Add the role-specific form fields
                  _getRoleSpecificFields(),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(role: _selectedRole!),
                          ),
                        );
                      }
                    },
                    child: Text('Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7AC143), // Accent color for buttons
                      padding: EdgeInsets.symmetric(vertical: 15),
                      textStyle: TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getRoleSpecificFields() {
    if (_selectedRole == 'User') {
      return Column(
        children: [
          TextFormField(
            controller: firstNameController,
            decoration: InputDecoration(
              labelText: 'First Name',
              labelStyle: TextStyle(color: Color(0xFF333333)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Color(0xFFEBEBEB),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your first name';
              }
              return null;
            },
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: lastNameController,
            decoration: InputDecoration(
              labelText: 'Last Name',
              labelStyle: TextStyle(color: Color(0xFF333333)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Color(0xFFEBEBEB),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your last name';
              }
              return null;
            },
          ),
        ],
      );
    } else if (_selectedRole == 'Insurance Provider') {
      return Column(
        children: [
          TextFormField(
            controller: insuranceProviderController,
            decoration: InputDecoration(
              labelText: 'Insurance Provider Name',
              labelStyle: TextStyle(color: Color(0xFF333333)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Color(0xFFEBEBEB),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the insurance provider name';
              }
              return null;
            },
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: stateController,
            decoration: InputDecoration(
              labelText: 'State',
              labelStyle: TextStyle(color: Color(0xFF333333)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Color(0xFFEBEBEB),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your state';
              }
              return null;
            },
          ),
        ],
      );
    } else if (_selectedRole == 'Service Provider') {
      return Column(
        children: [
          TextFormField(
            controller: serverNumberController,
            decoration: InputDecoration(
              labelText: 'Server Number',
              labelStyle: TextStyle(color: Color(0xFF333333)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Color(0xFFEBEBEB),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a server number';
              }
              return null;
            },
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: idController,
            decoration: InputDecoration(
              labelText: 'ID',
              labelStyle: TextStyle(color: Color(0xFF333333)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Color(0xFFEBEBEB),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your ID';
              }
              return null;
            },
          ),
        ],
      );
    }
    return SizedBox.shrink();
  }
}
