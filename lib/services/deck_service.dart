import 'dart:math';

import '../models/playing_card.dart';

class DeckService {
  DeckService({Random? random})
    : _random = random ?? Random(),
      _fixedCards = null;

  DeckService.fixed(List<PlayingCard> cards)
    : _random = Random(0),
      _fixedCards = List.unmodifiable(cards);

  final Random _random;
  final List<PlayingCard>? _fixedCards;
  List<PlayingCard> _cards = [];

  void reset() {
    final fixed = _fixedCards;
    if (fixed != null) {
      _cards = List<PlayingCard>.of(fixed);
      return;
    }

    _cards = [
      for (final suit in PlayingCardSuit.values)
        for (final rank in PlayingCardRank.values)
          PlayingCard(rank: rank, suit: suit),
    ]..shuffle(_random);
  }

  PlayingCard draw() {
    if (_cards.isEmpty) {
      throw StateError('The deck is empty.');
    }
    return _cards.removeAt(0);
  }
}
