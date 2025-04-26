class UserLookup {
  final String userID;
  final String userName;
  final String email;

  UserLookup({
    required this.userID,
    required this.userName,
    required this.email,
  });

//user details is retrieved
  Future<Map<String, String>> fetchUserDetails() async {
    // Simulate an API call or database query
    await Future.delayed(Duration(seconds: 2)); // Simulated delay

    // this response is mocked
    return {
      'userID': userID,
      'userName': userName,
      'email': email,
      'status': 'Active',
    };
  }

  // Method to validate the email format
  bool validateEmail() {
    // Simple email validation regex
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }
}

void main() async {
  // Example usage
  final userLookup = UserLookup(
    userID: 'U12345',
    userName: 'Jane Doe',
    email: 'cj.emenanjor@example.com',
  );

if (userLookup.validateEmail()) {
    print('Fetching user details...');
    final details = await userLookup.fetchUserDetails();
    print('User Details: $details');
  } else {
    print('Invalid email format.');
  }
}