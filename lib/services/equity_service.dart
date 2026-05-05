import 'package:poker/poker.dart' as poker;
import '../models/game_phase.dart';
import '../models/playing_card.dart';

abstract class EquityCalculator {
  Future<List<double>> calculate({
    required List<List<PlayingCard>> holeCards,
    required List<PlayingCard> board,
    required GamePhase phase,
  });
}

class EquityService implements EquityCalculator {
  const EquityService({
    this.preflopIterations = 5000,
    this.flopIterations = 10000,
  });

  final int preflopIterations;
  final int flopIterations;

  @override
  Future<List<double>> calculate({
    required List<List<PlayingCard>> holeCards,
    required List<PlayingCard> board,
    required GamePhase phase,
  }) async {
    if (holeCards.length < 2 || !_shouldCalculate(phase)) {
      return List.filled(holeCards.length, 0);
    }

    final players = holeCards
        .map((cards) => poker.HandRange.parse(cards.map(_code).join()))
        .toList();
    final communityCards = poker.ImmutableCardSet.parse(
      board.map(_code).join(),
    );
    final scores = List<double>.filled(players.length, 0);
    var samples = 0;

    try {
      if (phase == GamePhase.turnDealt) {
        for (final matchup in poker.ExhaustiveEvaluator(
          communityCards: communityCards,
          players: players,
        )) {
          _scoreMatchup(scores, matchup);
          samples += 1;
        }
      } else {
        final iterations = phase == GamePhase.preflopDealt
            ? preflopIterations
            : flopIterations;
        for (final matchup in poker.MontecarloEvaluator(
          communityCards: communityCards,
          players: players,
        ).take(iterations)) {
          _scoreMatchup(scores, matchup);
          samples += 1;
        }
      }
    } on poker.NoPossibleCombinationException {
      return List.filled(holeCards.length, 0);
    }

    if (samples == 0) {
      return List.filled(holeCards.length, 0);
    }

    return scores.map((score) => score / samples).toList();
  }

  static bool _shouldCalculate(GamePhase phase) {
    return phase == GamePhase.preflopDealt ||
        phase == GamePhase.flopDealt ||
        phase == GamePhase.turnDealt;
  }

  static void _scoreMatchup(List<double> scores, poker.Matchup matchup) {
    final share = 1 / matchup.wonPlayerIndexes.length;
    for (final index in matchup.wonPlayerIndexes) {
      scores[index] += share;
    }
  }

  static String _code(PlayingCard card) => card.code;
}
