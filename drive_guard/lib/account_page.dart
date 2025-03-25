
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'privacy_page.dart';

class AccountPage extends StatefulWidget {
  static const keyLanguage = 'key-language';
  static const keyPassword = 'key-password';

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
     _checkAuthToken();
  }

// Function to check if a user is authenticated
Future<void> _checkAuthToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');

  if (token == null) {
    Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => LoginPageWidget()), // Redirect to login
  );
  }
}

  // Function to pick an image
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      _saveProfileImage(pickedFile.path);
    }
  }

Future<void> _saveProfileImage(String imagePath) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token'); // Get user token
  if (token != null) {
    await prefs.setString('profile_image_$token', imagePath); // Store image with token key
  }
}

Future<void> _loadProfileImage() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');
  if (token != null) {
    final imagePath = prefs.getString('profile_image_$token'); // Load image for user
    if (imagePath != null) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }
}

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            SizedBox(height: 80),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => SimpleSettingsTile(
        leading: Icon(Icons.person, color: Colors.blue[100]),
        title: 'Account Settings',
        subtitle: 'Privacy, Security, Language',
        child: SettingsScreen(
          children: <Widget>[
            buildProfilePicture(context),
            PrivacyPage(),
            buildChooseLang(),
          ],
        ),
      );


  Widget buildProfilePicture(BuildContext context) {
    return SimpleSettingsTile(
      title: 'Profile Picture',
      subtitle: 'Tap to change',
      leading: GestureDetector(
        onTap: _showImagePickerDialog,
        child: CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey[300],
          backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
          child: _profileImage == null
              ? Icon(Icons.person, size: 40, color: Colors.white)
              : null,
        ),
      ),
      onTap: _showImagePickerDialog,
    );
  }

  // Possible implement functionality in the future
  Widget buildChooseLang() => DropDownSettingsTile(
        title: 'Language',
        settingKey: AccountPage.keyLanguage,
        selected: 1,
        values: <int, String>{
          1: 'English',
          2: 'Spanish',
          3: 'Chinese',
        },
        onChange: (language) {},
      );
}