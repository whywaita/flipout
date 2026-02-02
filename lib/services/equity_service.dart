import 'package:poker/poker.dart';
import '../models/player.dart';

/// Service for calculating equity (win probability)
class EquityService {
  /// Calculate equity for all players
  /// Returns a map of player index to equity percentage (0-100)
  static Future<Map<int, double>> calculateEquity({
    required List<Player> players,
    required List<Card> communityCards,
    int simulations = 10000,
  }) async {
    // Create hand ranges for each player
    final handRanges = players.map((player) {
      // Parse hole cards into HandRange format
      final cards = player.holeCards;
      if (cards.length != 2) {
        throw ArgumentError(
            'Player ${player.index} must have exactly 2 hole cards');
      }
      final cardStr = '${_cardToString(cards[0])}${_cardToString(cards[1])}';
      return HandRange.parse(cardStr);
    }).toList();

    // Create community card set
    final ImmutableCardSet communityCardSet;
    if (communityCards.isEmpty) {
      communityCardSet = const ImmutableCardSet.empty();
    } else {
      communityCardSet = ImmutableCardSet.parse(
        communityCards.map(_cardToString).join(''),
      );
    }

    // Run Monte Carlo simulation
    final evaluator = MontecarloEvaluator(
      communityCards: communityCardSet,
      players: handRanges,
    );

    final wins = List<int>.filled(players.length, 0);
    int totalGames = 0;

    for (final matchup in evaluator.take(simulations)) {
      totalGames++;
      final wonIndexes = matchup.wonPlayerIndexes;
      for (final idx in wonIndexes) {
        wins[idx]++;
      }
    }

    // Calculate equity percentages
    final equities = <int, double>{};
    for (int i = 0; i < players.length; i++) {
      equities[i] = (wins[i] / totalGames) * 100.0;
    }

    return equities;
  }

  static String _cardToString(Card card) {
    final rankStr = _rankToString(card.rank);
    final suitStr = _suitToString(card.suit);
    return '$rankStr$suitStr';
  }

  static String _rankToString(Rank rank) {
    switch (rank) {
      case Rank.deuce:
        return '2';
      case Rank.trey:
        return '3';
      case Rank.four:
        return '4';
      case Rank.five:
        return '5';
      case Rank.six:
        return '6';
      case Rank.seven:
        return '7';
      case Rank.eight:
        return '8';
      case Rank.nine:
        return '9';
      case Rank.ten:
        return 'T';
      case Rank.jack:
        return 'J';
      case Rank.queen:
        return 'Q';
      case Rank.king:
        return 'K';
      case Rank.ace:
        return 'A';
    }
  }

  static String _suitToString(Suit suit) {
    switch (suit) {
      case Suit.spade:
        return 's';
      case Suit.heart:
        return 'h';
      case Suit.diamond:
        return 'd';
      case Suit.club:
        return 'c';
    }
  }
}
