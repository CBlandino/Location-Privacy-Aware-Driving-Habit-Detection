import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'privacy_page.dart';

// AccountPage is a settings screen for user account management.
// It includes profile picture management, privacy settings, and language selection.
class AccountPage extends StatefulWidget {
  // Keys for SharedPreferences storage

  // Key for storing language preference
  static const keyLanguage = 'key-language'; 
  // Key for storing password (unused in current implementation)
  static const keyPassword = 'key-password'; 
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // Stores the user's profile image file
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    // Load saved profile image on initialization
    _loadProfileImage();
    // Verify user is authenticated
    _checkAuthToken();
  }

  // Checks if the user has a valid authentication token.
  // If not, redirects to the login page.
  Future<void> _checkAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPageWidget()),
      );
    }
  }

  // Opens image picker to select an image from gallery or camera.
  // [source] specifies whether to use camera or gallery.
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      _saveProfileImage(pickedFile.path);
    }
  }

  // Saves the profile image path to SharedPreferences.
  // The image is stored with a user-specific key using their auth token.
  Future<void> _saveProfileImage(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    if (token != null) {
      await prefs.setString('profile_image_$token', imagePath);
    }
  }

  // Loads the profile image from SharedPreferences if it exists.
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (token != null) {
      final imagePath = prefs.getString('profile_image_$token');
      if (imagePath != null) {
        setState(() {
          _profileImage = File(imagePath);
        });
      }
    }
  }

  // Shows a bottom sheet dialog for choosing image source (camera or gallery).
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
        leading: Icon(Icons.person_2_outlined, color: Colors.black),
        title: 'Account Settings',
        child: SettingsScreen(
          title: 'Account Settings',
          children: <Widget>[
            buildProfilePicture(context),
            //PrivacyPage(),
            buildChooseLang(),
          ],
        ),
      );

  // Builds the profile picture settings tile with circular avatar.
  // Tapping opens the image picker dialog.
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

  // Builds the language selection dropdown.
  // Currently non-functional (onChange is empty).
  // TODO: Implement language change functionality
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