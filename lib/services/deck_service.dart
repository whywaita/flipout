import 'dart:math';
import 'package:poker/poker.dart';

/// Service for managing a deck of cards
class DeckService {
  late List<Card> _deck;
  final Random _random = Random();

  DeckService() {
    reset();
  }

  /// Reset the deck to a full 52-card deck and shuffle
  void reset() {
    _deck = [];
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        _deck.add(Card(rank, suit));
      }
    }
    shuffle();
  }

  /// Shuffle the deck
  void shuffle() {
    _deck.shuffle(_random);
  }

  /// Draw a single card from the deck
  Card drawCard() {
    if (_deck.isEmpty) {
      throw StateError('No cards left in deck');
    }
    return _deck.removeLast();
  }

  /// Draw multiple cards from the deck
  List<Card> drawCards(int count) {
    return List.generate(count, (_) => drawCard());
  }

  /// Get remaining card count
  int get remainingCards => _deck.length;
}
