import 'dart:math';

class IDGenerator {
  final int length;
  final bool includeLetters;
  final bool includeNumbers;

  IDGenerator({
    this.length = 8, // Default length of the ID
    this.includeLetters = true,
    this.includeNumbers = true,
  });

  // Method to generate a random ID
  String generateID() {
    if (!includeLetters && !includeNumbers) {
      throw ArgumentError('At least one of includeLetters or includeNumbers must be true.');
    }

    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    String characters = '';

    if (includeLetters) characters += letters;
    if (includeNumbers) characters += numbers;

    final random = Random();
    return List.generate(length, (index) => characters[random.nextInt(characters.length)]).join();
  }
}

void main() {
  // Example usage
  final idGenerator = IDGenerator(length: 12, includeLetters: true, includeNumbers: true);
  final uniqueID = idGenerator.generateID();
  print('Generated ID: $uniqueID');
}