import 'dart:async';

import 'package:poker/poker.dart' as poker;

import '../models/playing_card.dart';

enum EquityMode { preflop, flop, turn }

abstract interface class EquityService {
  Future<List<double>> calculate({
    required List<List<PlayingCard>> holeCards,
    required List<PlayingCard> communityCards,
    required EquityMode mode,
    int? simulations,
  });
}

class PokerEquityService implements EquityService {
  const PokerEquityService();

  static const preflopSimulations = 5000;
  static const flopSimulations = 10000;

  @override
  Future<List<double>> calculate({
    required List<List<PlayingCard>> holeCards,
    required List<PlayingCard> communityCards,
    required EquityMode mode,
    int? simulations,
  }) {
    return Future<List<double>>(
      () => _calculateSync(
        holeCards: holeCards,
        communityCards: communityCards,
        mode: mode,
        simulations: simulations,
      ),
    );
  }

  List<double> _calculateSync({
    required List<List<PlayingCard>> holeCards,
    required List<PlayingCard> communityCards,
    required EquityMode mode,
    int? simulations,
  }) {
    final players = [
      for (final cards in holeCards)
        poker.HandRange.parse(cards.map((card) => card.code).join()),
    ];
    final board = poker.ImmutableCardSet.parse(
      communityCards.map((card) => card.code).join(),
    );

    final Iterable<poker.Matchup> matchups = switch (mode) {
      EquityMode.turn => poker.ExhaustiveEvaluator(
        communityCards: board,
        players: players,
      ),
      EquityMode.preflop || EquityMode.flop =>
        poker.MontecarloEvaluator(communityCards: board, players: players).take(
          simulations ??
              (mode == EquityMode.preflop
                  ? preflopSimulations
                  : flopSimulations),
        ),
    };

    final wonShares = List<double>.filled(holeCards.length, 0);
    var iterations = 0;

    for (final matchup in matchups) {
      iterations += 1;
      final winners = matchup.wonPlayerIndexes;
      final share = 1 / winners.length;
      for (final winner in winners) {
        wonShares[winner] += share;
      }
    }

    if (iterations == 0) {
      return List<double>.filled(holeCards.length, 1 / holeCards.length);
    }

    return [for (final won in wonShares) won / iterations];
  }
}
