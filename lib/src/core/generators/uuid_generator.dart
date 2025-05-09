import 'dart:math';

class UUIDGenerator {
  static final _secureRandom = Random.secure();

  /// Generates a RFC-4122 v4 UUID (random).
  ///
  /// Returns a String containing a UUID in the format:
  /// xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx where x is any hexadecimal digit
  /// and y is one of 8, 9, A, or B.
  ///
  /// Example:
  /// ```dart
  /// final id = UUIDGenerator.v4(); // e.g. "f47ac10b-58cc-4372-a567-0e02b2c3d479"
  /// ```
  static String v4() {
    // Create a static Random instance for better performance when generating multiple UUIDs

    // Generate 16 random bytes
    final List<int> bytes =
        List<int>.generate(16, (_) => _secureRandom.nextInt(256));

    // Per RFC4122 §4.4, set bits 12-15 of time_hi_and_version to 0100 (version 4)
    bytes[6] = (bytes[6] & 0x0F) | 0x40;

    // Per RFC4122 §4.4, set bits 6-7 of clock_seq_hi_and_reserved to 10 (variant)
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    // Convert to hex and insert dashes using StringBuffer for efficiency
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(bytes[i].toRadixString(16).padLeft(2, '0'));
    }

    return buffer.toString();
  }
}
