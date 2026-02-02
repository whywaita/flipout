import 'package:flutter_test/flutter_test.dart';
import 'package:flipout/services/hand_evaluator_service.dart';
import 'package:flipout/models/player.dart';
import 'package:poker/poker.dart';

void main() {
  group('HandEvaluatorService', () {
    test('ロイヤルフラッシュが勝つ', () async {
      final players = [
        Player(
          index: 0,
          name: 'Player 1',
          holeCards: [
            Card(Rank.ace, Suit.spade),
            Card(Rank.king, Suit.spade),
          ],
        ),
        Player(
          index: 1,
          name: 'Player 2',
          holeCards: [
            Card(Rank.deuce, Suit.heart),
            Card(Rank.trey, Suit.heart),
          ],
        ),
      ];

      final communityCards = [
        Card(Rank.queen, Suit.spade),
        Card(Rank.jack, Suit.spade),
        Card(Rank.ten, Suit.spade),
        Card(Rank.four, Suit.club),
        Card(Rank.five, Suit.diamond),
      ];

      final winners = await HandEvaluatorService.evaluateShowdown(
        players: players,
        communityCards: communityCards,
      );

      expect(winners.length, equals(1));
      expect(winners[0].index, equals(0));
      expect(winners[0].isWinner, isTrue);
      expect(winners[0].winningHand?.length, equals(5));
    });

    test('同じハンドでスプリットポット', () async {
      final players = [
        Player(
          index: 0,
          name: 'Player 1',
          holeCards: [
            Card(Rank.ace, Suit.spade),
            Card(Rank.king, Suit.spade),
          ],
        ),
        Player(
          index: 1,
          name: 'Player 2',
          holeCards: [
            Card(Rank.ace, Suit.heart),
            Card(Rank.king, Suit.heart),
          ],
        ),
      ];

      final communityCards = [
        Card(Rank.queen, Suit.diamond),
        Card(Rank.jack, Suit.diamond),
        Card(Rank.ten, Suit.diamond),
        Card(Rank.nine, Suit.diamond),
        Card(Rank.eight, Suit.diamond),
      ];

      final winners = await HandEvaluatorService.evaluateShowdown(
        players: players,
        communityCards: communityCards,
      );

      // 両方ともストレートフラッシュでスプリット
      expect(winners.length, equals(2));
      expect(winners[0].isWinner, isTrue);
      expect(winners[1].isWinner, isTrue);
    });

    test('コミュニティカードが5枚でない場合にエラー', () {
      final players = [
        Player(
          index: 0,
          name: 'Player 1',
          holeCards: [
            Card(Rank.ace, Suit.spade),
            Card(Rank.king, Suit.spade),
          ],
        ),
      ];

      final communityCards = [
        Card(Rank.queen, Suit.spade),
        Card(Rank.jack, Suit.spade),
        Card(Rank.ten, Suit.spade),
      ];

      expect(
        () => HandEvaluatorService.evaluateShowdown(
          players: players,
          communityCards: communityCards,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
