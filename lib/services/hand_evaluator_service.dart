import 'package:poker/poker.dart' as poker;

import '../models/playing_card.dart';

class HandEvaluatorService {
  const HandEvaluatorService();

  ShowdownResult evaluate({
    required List<List<PlayingCard>> holeCards,
    required List<PlayingCard> board,
  }) {
    if (board.length != 5) {
      throw ArgumentError.value(board.length, 'board.length', 'must be 5');
    }

    final playerResults = [
      for (final cards in holeCards) _bestFive([...cards, ...board]),
    ];

    var bestPower = -1;
    final winners = <int>{};
    for (var index = 0; index < playerResults.length; index += 1) {
      final power = playerResults[index].power;
      if (power > bestPower) {
        winners
          ..clear()
          ..add(index);
        bestPower = power;
      } else if (power == bestPower) {
        winners.add(index);
      }
    }

    final boardHighlights = <PlayingCard>{};
    for (final winner in winners) {
      boardHighlights.addAll(
        playerResults[winner].bestFiveCards.where(board.contains),
      );
    }

    return ShowdownResult(
      players: playerResults,
      winningPlayerIndexes: winners,
      boardHighlights: boardHighlights,
    );
  }

  PlayerHandResult _bestFive(List<PlayingCard> sevenCards) {
    PlayerHandResult? best;

    for (final candidate in _fiveCardCombinations(sevenCards)) {
      final madeHand = poker.MadeHand.best(_toPokerSet(candidate));
      final result = PlayerHandResult(
        bestFiveCards: candidate.toSet(),
        power: madeHand.power,
        handLabel: _labelFor(madeHand.type),
      );

      if (best == null || result.power > best.power) {
        best = result;
      }
    }

    return best!;
  }

  Iterable<List<PlayingCard>> _fiveCardCombinations(
    List<PlayingCard> cards,
  ) sync* {
    final indexes = List<int>.generate(5, (index) => index);

    while (true) {
      yield [for (final index in indexes) cards[index]];

      var position = indexes.length - 1;
      while (position >= 0 &&
          indexes[position] == cards.length - 5 + position) {
        position -= 1;
      }

      if (position < 0) {
        return;
      }

      indexes[position] += 1;
      for (var next = position + 1; next < indexes.length; next += 1) {
        indexes[next] = indexes[next - 1] + 1;
      }
    }
  }

  poker.ImmutableCardSet _toPokerSet(Iterable<PlayingCard> cards) {
    return poker.ImmutableCardSet.of(cards.map((card) => card.toPokerCard()));
  }

  String _labelFor(poker.MadeHandType type) {
    return switch (type) {
      poker.MadeHandType.highcard => 'High card',
      poker.MadeHandType.pair => 'Pair',
      poker.MadeHandType.twoPairs => 'Two pair',
      poker.MadeHandType.trips => 'Trips',
      poker.MadeHandType.straight => 'Straight',
      poker.MadeHandType.flush => 'Flush',
      poker.MadeHandType.fullHouse => 'Full house',
      poker.MadeHandType.quads => 'Quads',
      poker.MadeHandType.straightFlush => 'Straight flush',
    };
  }
}

class ShowdownResult {
  const ShowdownResult({
    required this.players,
    required this.winningPlayerIndexes,
    required this.boardHighlights,
  });

  final List<PlayerHandResult> players;
  final Set<int> winningPlayerIndexes;
  final Set<PlayingCard> boardHighlights;
}

class PlayerHandResult {
  const PlayerHandResult({
    required this.bestFiveCards,
    required this.power,
    required this.handLabel,
  });

  final Set<PlayingCard> bestFiveCards;
  final int power;
  final String handLabel;
}
