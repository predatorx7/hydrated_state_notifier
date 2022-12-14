import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:hydrated_state_notifier_hive/hydrated_state_notifier_hive.dart';
import 'package:test/test.dart';

void main() {
  group('HydratedAesCipher', () {
    const password = 'hydration';
    final bytes = sha256.convert(utf8.encode(password)).bytes;
    test('creates an instance', () {
      expect(HydratedAesCipher(bytes), isNotNull);
    });

    test('is a HiveAesCipher', () {
      expect(HydratedAesCipher(bytes), isA<HiveAesCipher>());
    });
  });
}
