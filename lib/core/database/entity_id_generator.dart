import 'dart:math';

/// SQLite, Dart ve Firestore'un güvenle taşıyabildiği pozitif 52 bit kimlikler
/// üretir. Yerel auto-increment kimliklerin farklı cihazlarda çakışmasını önler.
class EntityIdGenerator {
  EntityIdGenerator._();

  static final Random _random = Random.secure();
  static const int _partLimit = 1 << 26;

  static int next() {
    var id = 0;
    while (id == 0) {
      id = (_random.nextInt(_partLimit) << 26) | _random.nextInt(_partLimit);
    }
    return id;
  }
}
