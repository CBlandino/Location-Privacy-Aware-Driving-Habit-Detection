DriveGuard - Safe Driving Monitoring System

What is DriveGuard?
DriveGuard is a mobile app that helps drivers track their trips and improve safety. It is designed for regular users, insurance companies, and administrators.

What's Inside
- User App: Tracks your drives, shows safety scores, and keeps trip history
- Insurance View: Lets insurance companies check driver safety data
- Admin Tools: For managing users and system settings

How It Works
- Mobile app records your driving (speed, braking, etc.)
- Calculates a safety score for each trip
- Shows your driving history and improvements
- Insurance companies can view driver data
- Admins can manage all accounts

Setup Instructions

Database Setup
To start the database:
./db_start.sh

To reset the database (warning: erases all data):
./db_delete.sh

Server Setup
Edit ipconfig.dart to set your server address:
static String server = 'http://your-server-address:8080';

Run the App
1. Install Flutter
2. Get dependencies:
flutter pub get
3. Run the app:
flutter run

Main Features
- Tracks your driving trips with GPS
- Shows how safely you're driving
- Keeps history of all your trips
- Insurance companies can see driver scores
- Admins can manage all user accounts

Important Notes
- Needs location permissions to work
- Takes a moment to connect to GPS
- Server address must match on all devices
