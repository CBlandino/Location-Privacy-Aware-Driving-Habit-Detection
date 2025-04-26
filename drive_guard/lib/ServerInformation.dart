class ServerInformation {
  final String baseUrl;
  final int port;
  final String apiKey;

  ServerInformation({
    required this.baseUrl,
    required this.port,
    required this.apiKey,
  });

  String get fullUrl => '$baseUrl:$port';

  @override
  String toString() {
    return 'ServerInformation(baseUrl: $baseUrl, port: $port, apiKey: $apiKey)';
  }
}