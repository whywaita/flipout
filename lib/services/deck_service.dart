import 'dart:math';
import '../models/playing_card.dart';

class DeckService {
  DeckService({int? randomSeed})
    : _random = Random(randomSeed),
      _orderedCards = null {
    reset();
  }

  DeckService.ordered(List<PlayingCard> cards)
    : _random = Random(0),
      _orderedCards = List.unmodifiable(cards) {
    reset();
  }

  final Random _random;
  final List<PlayingCard>? _orderedCards;
  late List<PlayingCard> _remaining;

  void reset() {
    _remaining = List.of(_orderedCards ?? PlayingCard.standardDeck());
    if (_orderedCards == null) {
      _remaining.shuffle(_random);
    }
  }

  PlayingCard draw() {
    if (_remaining.isEmpty) {
      throw StateError('Deck is empty');
    }

    return _remaining.removeAt(0);
  }

  List<PlayingCard> drawMany(int count) {
    return List.generate(count, (_) => draw());
  }

  int get remainingCount => _remaining.length;
}
