class AppConfig {
  static String server = 'http://10.0.2.2:8080'; // Default to localhost

  static void setServer(String newServer) {
    server = newServer;
  }
}