import 'package:poker/poker.dart' as poker;
import '../models/playing_card.dart';

class ShowdownResult {
  const ShowdownResult({
    required this.winnerIndexes,
    required this.winningCardsByPlayer,
  });

  final Set<int> winnerIndexes;
  final Map<int, Set<PlayingCard>> winningCardsByPlayer;
}

class HandEvaluatorService {
  const HandEvaluatorService();

  ShowdownResult evaluate({
    required List<List<PlayingCard>> holeCards,
    required List<PlayingCard> board,
  }) {
    if (board.length != 5) {
      throw ArgumentError.value(board.length, 'board.length', 'must be 5');
    }

    var bestPower = -1;
    final powers = <int>[];
    final bestCards = <Set<PlayingCard>>[];

    for (final playerCards in holeCards) {
      final sevenCards = [...playerCards, ...board];
      final best = _bestFive(sevenCards);
      powers.add(best.power);
      bestCards.add(best.cards);
      if (best.power > bestPower) {
        bestPower = best.power;
      }
    }

    final winnerIndexes = <int>{};
    final winningCardsByPlayer = <int, Set<PlayingCard>>{};
    for (var i = 0; i < powers.length; i += 1) {
      if (powers[i] == bestPower) {
        winnerIndexes.add(i);
        winningCardsByPlayer[i] = bestCards[i];
      }
    }

    return ShowdownResult(
      winnerIndexes: winnerIndexes,
      winningCardsByPlayer: winningCardsByPlayer,
    );
  }

  _BestHand _bestFive(List<PlayingCard> cards) {
    var bestPower = -1;
    Set<PlayingCard> bestCards = {};

    for (final combination in _fiveCardCombinations(cards)) {
      final madeHand = poker.MadeHand.best(
        poker.ImmutableCardSet.of(combination.map(_toPokerCard).toSet()),
      );

      if (madeHand.power > bestPower) {
        bestPower = madeHand.power;
        bestCards = combination.toSet();
      }
    }

    return _BestHand(power: bestPower, cards: bestCards);
  }

  Iterable<List<PlayingCard>> _fiveCardCombinations(
    List<PlayingCard> cards,
  ) sync* {
    for (var a = 0; a < cards.length - 4; a += 1) {
      for (var b = a + 1; b < cards.length - 3; b += 1) {
        for (var c = b + 1; c < cards.length - 2; c += 1) {
          for (var d = c + 1; d < cards.length - 1; d += 1) {
            for (var e = d + 1; e < cards.length; e += 1) {
              yield [cards[a], cards[b], cards[c], cards[d], cards[e]];
            }
          }
        }
      }
    }
  }

  poker.Card _toPokerCard(PlayingCard card) {
    return poker.Card.parse(card.code);
  }
}

class _BestHand {
  const _BestHand({required this.power, required this.cards});

  final int power;
  final Set<PlayingCard> cards;
}
