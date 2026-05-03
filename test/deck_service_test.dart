import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flipout/services/deck_service.dart';

void main() {
  test('draws a shuffled 52 card deck without duplicates', () {
    final deck = DeckService(random: Random(7))..reset();

    final cards = List.generate(52, (_) => deck.draw());

    expect(cards.toSet(), hasLength(52));
    expect(() => deck.draw(), throwsStateError);
  });
}
