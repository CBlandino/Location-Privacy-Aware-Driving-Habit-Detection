import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
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

  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFEEEEEE);

  final _formKey = GlobalKey<FormState>();
  late SharedPreferences _prefs;
  bool _isProcessing = false;
  final String _selectedRole = 'user';
  bool _isSignupMode = false;
  

  // Controllers
  final emailController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final passwordController = TextEditingController();
  final insuranceProviderController = TextEditingController();
  final stateController = TextEditingController();
  final serverNumberController = TextEditingController();
  final idController = TextEditingController();
  final _adminIdController = TextEditingController();
final _serverNumberController = TextEditingController();


  late TabController _tabController;
  final String server = AppConfig.server;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    passwordController.dispose();
    insuranceProviderController.dispose();
    stateController.dispose();
    serverNumberController.dispose();
    idController.dispose();
    _tabController.dispose();
    
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (_isProcessing || !_formKey.currentState!.validate()) return;
    
    setState(() => _isProcessing = true);
    
    try {
      if (_isSignupMode) {
        await _signup();
      } else {
        await _login();
      }
    } catch (error) {
      _showErrorDialog(_isSignupMode 
          ? 'An error occurred during signup' 
          : 'The server is down. Please try again later.');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _signup() async {
    final url = '$server/signup';
    final data = _buildAuthData();

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      await _handleSuccessfulAuth(response.body);
    } else {
      final responseData = await _parseJson(response.body);
      _showErrorDialog(responseData['message'] ?? 'Signup failed');
    }
  }

  Future<void> _login() async {
    final url = '$server/login';
    final data = _buildAuthData();

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 202) {
      await _handleSuccessfulAuth(response.body);
    } else {
      final responseData = await _parseJson(response.body);
      _showErrorDialog(responseData['message'] ?? 'Login failed');
    }
  }

  Map<String, dynamic> _buildAuthData() {
    final data = {
      'email': emailController.text,
      'password': passwordController.text,
      'role': _selectedRole,
    };

    if (_selectedRole == 'user') {
      if (_isSignupMode) {
        data.addAll({
          'first_name': firstNameController.text,
          'last_name': lastNameController.text,
        });
      }
    } 
    else if (_selectedRole == 'admin') {
      if (_isSignupMode) {
        data.addAll({
          'first_name': firstNameController.text,
          'last_name': lastNameController.text,
          'admin_id': idController.text,
          'server_number': serverNumberController.text,
        });
      } else {
        data['admin_id'] = idController.text;
        data['server_number'] = serverNumberController.text;
      }
    } 
    else if (_selectedRole == 'insurance') {
      if (_isSignupMode) {
        data.addAll({
          'first_name': insuranceProviderController.text,
          'last_name': stateController.text,
          'password': idController.text,
        });
      } else {
        data['password'] = idController.text;
      }
    }

    return data;
  }

  Future<void> _handleSuccessfulAuth(String responseBody) async {
    final responseData = json.decode(responseBody);
    final token = responseData['access_token'];
    await _prefs.setString('access_token', token);

    final decodedToken = JwtDecoder.decode(token);
    final role = decodedToken['role'];

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(role: role)),
      );
    }
  }

  Future<Map<String, dynamic>> _parseJson(String responseBody) async {
    return await compute((String jsonString) {
      return json.decode(jsonString) as Map<String, dynamic>;
    }, responseBody);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final maxWidth = isWeb ? 500.0 : double.infinity;
    
    return Scaffold(
      backgroundColor: lightBlue,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: white,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildTabBar(),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildTextField('Email', emailController, Icons.email),
                            const SizedBox(height: 20),
                            ..._buildRoleSpecificFields(),
                            const SizedBox(height: 32),
                            _buildAuthButton(),
                            const SizedBox(height: 24),
                            _buildToggleAuthModeButton(),
                          ],
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

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          _isSignupMode ? 'Create Account' : 'Welcome Back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isSignupMode 
              ? 'Fill in your details to get started'
              : 'Login to continue to your account',
          style: TextStyle(
            fontSize: 16,
            color: grey,
          ),
        ),
      ],
    );
  }

Widget _buildTabBar() {
  return Container(
    height: 50,
    decoration: BoxDecoration(
      color: lightGrey,
      borderRadius: BorderRadius.circular(12),
    ),
    child: TabBar(
      controller: _tabController,
      tabs: [
        Container(
          alignment: Alignment.center,
          child: Text('Login', style: TextStyle(fontSize: 16)),
        ),
        Container(
          alignment: Alignment.center,
          child: Text('Sign Up', style: TextStyle(fontSize: 16)),
        ),
      ],
      onTap: (index) => setState(() => _isSignupMode = index == 1),
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: primaryBlue,
      ),
      labelColor: white,
      unselectedLabelColor: grey,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: EdgeInsets.zero,
      labelPadding: EdgeInsets.zero,
    ),
  );
}

  List<Widget> _buildRoleSpecificFields() {
    final fields = <Widget>[];
    
    if (_selectedRole == 'user') {
      if (_isSignupMode) {
        fields.addAll([
          _buildTextField('First Name', firstNameController, Icons.person),
          const SizedBox(height: 16),
          _buildTextField('Last Name', lastNameController, Icons.person),
          const SizedBox(height: 16),
        ]);
      }
      fields.add(_buildTextField('Password', passwordController, Icons.lock));
    } 
    else if (_selectedRole == 'insurance') {
      if (_isSignupMode) {
        fields.addAll([
          _buildTextField('Insurance Name', insuranceProviderController, Icons.business),
          const SizedBox(height: 16),
          _buildTextField('State', stateController, Icons.location_city),
          const SizedBox(height: 16),
        ]);
      }
      fields.add(_buildTextField('ID', idController, Icons.badge));
    } 
    else if (_selectedRole == 'admin') {
      if (_isSignupMode) {
        fields.addAll([
          _buildTextField('First Name', firstNameController, Icons.person),
          const SizedBox(height: 16),
          _buildTextField('Last Name', lastNameController, Icons.person),
          const SizedBox(height: 16),
          _buildTextField('Admin ID', idController, Icons.admin_panel_settings),
          const SizedBox(height: 16),
          _buildTextField('Server Number', serverNumberController, Icons.computer),
          const SizedBox(height: 16),
        ]);
      }
      fields.add(_buildTextField('Password', passwordController, Icons.lock));
    }

    return fields;
  }

 Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: label.toLowerCase().contains('password'),
      style: TextStyle(color: black, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: grey),
        prefixIcon: Icon(icon, color: primaryBlue, size: 24),
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: grey.withAlpha(75)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: grey.withAlpha(75)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }


  Widget _buildAuthButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _handleAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: primaryBlue.withAlpha(75),
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                _isSignupMode ? 'Sign Up' : 'Login',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleAuthModeButton() {
    return TextButton(
      onPressed: () {
        setState(() => _isSignupMode = !_isSignupMode);
        _tabController.animateTo(_isSignupMode ? 1 : 0);
      },
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      child: Text(
        _isSignupMode
            ? 'Already have an account? Login'
            : 'Need an account? Sign Up',
        style: const TextStyle(
          fontSize: 16,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
