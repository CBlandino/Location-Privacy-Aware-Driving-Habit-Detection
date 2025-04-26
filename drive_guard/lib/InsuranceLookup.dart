import 'dart:convert';
import 'dart:async'; // For TimeoutException
import 'package:http/http.dart' as http;

class InsuranceLookup {
  final String policyNumber;

  InsuranceLookup({required this.policyNumber});

  // Method to fetch insurance details from the backend
  Future<Map<String, String>> fetchInsuranceDetails() async {
    final url = Uri.parse('http://localhost:8080/insurance-details?policyNumber=$policyNumber');

    try {
      // Add a timeout to the HTTP request
      final response = await http.get(url).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Parse the JSON response
        final data = json.decode(response.body) as Map<String, dynamic>;
        return {
          'policyNumber': data['policyNumber'],
          'driverName': data['driverName'],
          'insuranceProvider': data['insuranceProvider'],
          'status': data['status'],
          'coverage': data['coverage'],
        };
      } else if (response.statusCode == 404) {
        throw Exception('Insurance policy not found');
      } else {
        throw Exception('Failed to fetch insurance details (HTTP ${response.statusCode})');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again later.');
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // Validates policy number
  bool validatePolicyNumber() {
    // Example validation: policy number must be alphanumeric and at least 6 characters
    if (policyNumber.isEmpty) {
      print('Policy number cannot be empty.');
      return false;
    }

    final regex = RegExp(r'^[a-zA-Z0-9]{6,}$');
    if (!regex.hasMatch(policyNumber)) {
      print('Policy number must be alphanumeric and at least 6 characters long.');
      return false;
    }

    return true;
  }
}

void main() async {
  // Example usage
  final insuranceLookup = InsuranceLookup(policyNumber: 'ABC12345');

  if (insuranceLookup.validatePolicyNumber()) {
    print('Fetching insurance details...');
    try {
      final details = await insuranceLookup.fetchInsuranceDetails();
      print('Insurance Details: $details');
    } catch (e) {
      print('Error: $e');
    }
  } else {
    print('Invalid policy number.');
  }
}