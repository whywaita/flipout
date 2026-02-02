import 'package:poker/poker.dart';
import '../models/player.dart';

/// Service for evaluating hands and determining winners
class HandEvaluatorService {
  /// Evaluate all players' hands and determine winner(s)
  /// Returns list of winners with their winning 5-card hands identified
  static Future<List<Player>> evaluateShowdown({
    required List<Player> players,
    required List<Card> communityCards,
  }) async {
    if (communityCards.length != 5) {
      throw ArgumentError(
          'Community cards must be exactly 5 cards for showdown');
    }

    final playerHands = <Player, MadeHand>{};

    // Evaluate each player's best hand
    for (final player in players) {
      if (player.holeCards.length != 2) {
        throw ArgumentError(
            'Player ${player.index} must have exactly 2 hole cards');
      }

      // Combine hole cards with community cards
      final allCards = [...player.holeCards, ...communityCards];
      final cardSet = ImmutableCardSet.of(allCards);

      // Get the best 5-card hand
      final madeHand = MadeHand.best(cardSet);
      playerHands[player] = madeHand;
    }

    // Find the best hand value
    final bestPower =
        playerHands.values.map((h) => h.power).reduce((a, b) => a > b ? a : b);

    // Identify all winners (players with the best hand)
    final winners = <Player>[];
    for (final entry in playerHands.entries) {
      if (entry.value.power == bestPower) {
        final player = entry.key;
        final winningCards = _identifyWinningCards(
          player.holeCards,
          communityCards,
          entry.value,
        );
        winners.add(player.copyWith(
          isWinner: true,
          winningHand: winningCards,
        ));
      }
    }

    return winners;
  }

  /// Identify which 5 cards make up the winning hand
  /// This is a brute-force approach: try all 21 combinations of 5 cards from 7
  static List<Card> _identifyWinningCards(
    List<Card> holeCards,
    List<Card> communityCards,
    MadeHand targetHand,
  ) {
    final allCards = [...holeCards, ...communityCards];

    // Generate all 5-card combinations from 7 cards
    final combinations = _generateCombinations(allCards, 5);

    // Find the combination that produces the target hand
    for (final combo in combinations) {
      final cardSet = ImmutableCardSet.of(combo);
      final madeHand = MadeHand.best(cardSet);

      if (madeHand.power == targetHand.power) {
        return combo;
      }
    }

    // Fallback: should not happen
    return allCards.take(5).toList();
  }

  /// Generate all combinations of k elements from a list
  static List<List<T>> _generateCombinations<T>(List<T> list, int k) {
    if (k == 0) return [[]];
    if (list.isEmpty) return [];

    final first = list.first;
    final rest = list.sublist(1);

    // Combinations that include the first element
    final withFirst = _generateCombinations(rest, k - 1)
        .map((combo) => [first, ...combo])
        .toList();

    // Combinations that don't include the first element
    final withoutFirst = _generateCombinations(rest, k);

    return [...withFirst, ...withoutFirst];
  }
}
