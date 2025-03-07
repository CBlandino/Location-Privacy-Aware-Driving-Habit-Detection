
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

class AccountPage extends StatelessWidget {
    static const keyLanguage = 'key-language';
    static const keyPassword = 'key-password';

  @override
  Widget build(BuildContext context) => SimpleSettingsTile(
    leading: Icon(
      Icons.person,
      color: Colors.blue[100],
    ),
    title: 'Account Settings',
    subtitle: 'Privacy, Security, Language',
    child: SettingsScreen(
      children: <Widget>[
        buildPrivacy(context),
        buildPassword(context),
      ]
    ),
  );


  Widget buildPassword(BuildContext context) => TextInputSettingsTile(
    title: 'Password',
    settingKey: keyPassword,
    //initialValue: password they already have,

  
  );




  Widget buildPrivacy(BuildContext context) => SimpleSettingsTile(
    title: 'Privacy',
    subtitle: '',
    leading: Icon(
      Icons.privacy_tip,
      color: Colors.red,
    ),
    onTap: () {
      
    },
  );




  Widget buildChooseLang() => DropDownSettingsTile(
    title: 'Language',
    settingKey: keyLanguage,
    selected: 1,
    values: <int, String>{
      1: 'English',
      2: 'Spanish',
      3: 'Chinese',
    },
    onChange: (language) {},
  );





}

