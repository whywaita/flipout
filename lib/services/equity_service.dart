import 'dart:math' as math;

import '../models/game_phase.dart';
import '../models/playing_card.dart';
import 'hand_evaluator_service.dart';

abstract class EquityCalculator {
  Future<List<double>> calculate({
    required List<List<PlayingCard>> holeCards,
    required List<PlayingCard> board,
    required GamePhase phase,
  });
}

/// Computes each player's share of the pot with the app's own evaluator.
///
/// Flop and turn are enumerated exactly; preflop is sampled because the
/// full 5-card runout space is too large to walk on every deal.
class EquityService implements EquityCalculator {
  const EquityService({
    this.preflopIterations = 5000,
    this.evaluator = const HandEvaluatorService(),
  });

  final int preflopIterations;
  final HandEvaluatorService evaluator;

  @override
  Future<List<double>> calculate({
    required List<List<PlayingCard>> holeCards,
    required List<PlayingCard> board,
    required GamePhase phase,
  }) async {
    if (holeCards.length < 2 || !_shouldCalculate(phase)) {
      return List.filled(holeCards.length, 0);
    }

    final used = {...holeCards.expand((cards) => cards), ...board};
    final deck = [
      for (final suit in CardSuit.values)
        for (final rank in CardRank.values)
          if (!used.contains(PlayingCard(rank: rank, suit: suit)))
            PlayingCard(rank: rank, suit: suit),
    ];
    final missing = 5 - board.length;
    final scores = List<double>.filled(holeCards.length, 0);
    var samples = 0;

    void score(List<PlayingCard> runout) {
      final fullBoard = [...board, ...runout];
      var best = -1;
      final winners = <int>[];
      for (var i = 0; i < holeCards.length; i += 1) {
        final value = evaluator.score([...holeCards[i], ...fullBoard]);
        if (value > best) {
          best = value;
          winners
            ..clear()
            ..add(i);
        } else if (value == best) {
          winners.add(i);
        }
      }
      final share = 1 / winners.length;
      for (final index in winners) {
        scores[index] += share;
      }
      samples += 1;
    }

    if (missing <= 2) {
      _forEachCombination(deck, missing, score);
    } else {
      final random = math.Random();
      for (var n = 0; n < preflopIterations; n += 1) {
        // Partial Fisher-Yates: the first `missing` cards become the runout.
        for (var i = 0; i < missing; i += 1) {
          final j = i + random.nextInt(deck.length - i);
          final tmp = deck[i];
          deck[i] = deck[j];
          deck[j] = tmp;
        }
        score(deck.sublist(0, missing));
      }
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

  static void _forEachCombination(
    List<PlayingCard> deck,
    int size,
    void Function(List<PlayingCard>) visit,
  ) {
    if (size == 0) {
      visit(const []);
      return;
    }
    if (size == 1) {
      for (final card in deck) {
        visit([card]);
      }
      return;
    }
    for (var i = 0; i < deck.length; i += 1) {
      for (var j = i + 1; j < deck.length; j += 1) {
        visit([deck[i], deck[j]]);
      }
    }
  }
}
