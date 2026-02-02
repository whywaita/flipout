import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flipout/models/settings.dart';

void main() {
  group('Settings', () {
    test('JSONシリアライズができる', () {
      final settings = Settings(
        playerCount: 4,
        playerNames: ['Alice', 'Bob', 'Charlie', 'Dave'],
        cardColorMode: CardColorMode.fourColor,
      );

      final json = jsonEncode(settings.toJson());
      expect(json, contains('playerCount'));
      expect(json, contains('Alice'));
    });

    test('JSONデシリアライズができる', () {
      final json = {
        'playerCount': 4,
        'playerNames': ['Alice', 'Bob', 'Charlie', 'Dave'],
        'cardColorMode':
            1, // CardColorMode.fourColorのインデックス (0: twoColor, 1: fourColor)
      };

      final settings = Settings.fromJson(json);

      expect(settings.playerCount, equals(4));
      expect(settings.playerNames.length, equals(4));
      expect(settings.playerNames[0], equals('Alice'));
      expect(settings.cardColorMode, equals(CardColorMode.fourColor));
    });

    test('JSON往復が正しく動作する', () {
      final original = Settings(
        playerCount: 6,
        playerNames: ['P1', 'P2', 'P3', 'P4', 'P5', 'P6'],
        cardColorMode: CardColorMode.twoColor,
      );

      final json = original.toJson();
      final restored = Settings.fromJson(json);

      expect(restored.playerCount, equals(original.playerCount));
      expect(restored.playerNames, equals(original.playerNames));
      expect(restored.cardColorMode, equals(original.cardColorMode));
    });
  });
}
