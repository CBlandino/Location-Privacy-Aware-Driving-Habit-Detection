import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'ipconfig.dart';

class TripService {
  static final String server = AppConfig.server;

  static Future<List<dynamic>> fetchPreviousTrips() async {
    final String url = '$server/previous_trips';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.isNotEmpty ? data : _getDummyData();
      } else {
        print('Error fetching trips');
        return _getDummyData();
      }
    } catch (error) {
      print('Error: $error');
      return _getDummyData();
    }
  }

  static List<Map<String, dynamic>> _getDummyData() {
    return [
      {"timestamp": 1711910400, "distance": 10.0},
      {"timestamp": 1711996800, "distance": 8.5},
      {"timestamp": 1712083200, "distance": 12.3},
    ];
  }
}
