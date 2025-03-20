import 'package:flutter/material.dart';
import 'login_page.dart'; // Ensure you import the correct file
import 'package:flutter_settings_screens/flutter_settings_screens.dart';


void main()  async{
  await Settings.init(cacheProvider: SharePreferenceCache());
  runApp(MyApp());  
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginPageWidget(), // Correct the reference here
    );
  }
}
