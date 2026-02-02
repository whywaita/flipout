import 'package:flutter_test/flutter_test.dart';
import 'package:flipout/models/player.dart';
import 'package:poker/poker.dart';

void main() {
  group('Player', () {
    test('copyWith()でプロパティを変更できる', () {
      final player = Player(
        index: 0,
        name: 'Alice',
        holeCards: [],
      );

      final updated = player.copyWith(
        name: 'Bob',
        equity: 50.0,
        isWinner: true,
      );

      expect(updated.index, equals(0));
      expect(updated.name, equals('Bob'));
      expect(updated.equity, equals(50.0));
      expect(updated.isWinner, isTrue);
      expect(updated.holeCards, isEmpty);
    });

    test('copyWith()でホールカードを変更できる', () {
      final player = Player(
        index: 0,
        name: 'Alice',
        holeCards: [],
      );

      final cards = [
        Card(Rank.ace, Suit.spade),
        Card(Rank.king, Suit.spade),
      ];

      final updated = player.copyWith(holeCards: cards);

      expect(updated.holeCards.length, equals(2));
      expect(updated.holeCards[0], equals(cards[0]));
    });
  });
}
