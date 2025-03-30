class AppConfig {
  static String server = 'http://18.191.9.236:8080'; // Default to localhost

  static void setServer(String newServer) {
    server = newServer;
  }
}