import 'package:flutter_test/flutter_test.dart';
import 'package:flipout/services/deck_service.dart';
import 'package:poker/poker.dart';

void main() {
  group('DeckService', () {
    late DeckService deckService;

    setUp(() {
      deckService = DeckService();
    });

    test('初期化時に52枚のカードがある', () {
      expect(deckService.remainingCards, equals(52));
    });

    test('drawCard()で1枚引ける', () {
      final card = deckService.drawCard();
      expect(card, isA<Card>());
      expect(deckService.remainingCards, equals(51));
    });

    test('drawCards()で指定枚数引ける', () {
      final cards = deckService.drawCards(5);
      expect(cards.length, equals(5));
      expect(deckService.remainingCards, equals(47));
    });

    test('52枚引いた後にエラーが発生する', () {
      deckService.drawCards(52);
      expect(
        () => deckService.drawCard(),
        throwsA(isA<StateError>()),
      );
    });

    test('reset()で52枚に戻る', () {
      deckService.drawCards(10);
      deckService.reset();
      expect(deckService.remainingCards, equals(52));
    });

    test('shuffle()でカードの順序が変わる', () {
      final deck1 = DeckService();
      final firstCards1 = deck1.drawCards(5);

      final deck2 = DeckService();
      final firstCards2 = deck2.drawCards(5);

      // 別のデッキではランダムなので順序が異なる可能性が高い
      expect(firstCards1, isNot(equals(firstCards2)));
    });
  });
}
