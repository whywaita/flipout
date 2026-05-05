import '../models/playing_card.dart';

class ShowdownResult {
  const ShowdownResult({
    required this.winnerIndexes,
    required this.winningCardsByPlayer,
    required this.handLabelByPlayer,
  });

  final Set<int> winnerIndexes;
  final Map<int, Set<PlayingCard>> winningCardsByPlayer;
  final Map<int, String> handLabelByPlayer;
}

enum HandRank {
  highCard,
  pair,
  twoPair,
  threeOfAKind,
  straight,
  flush,
  fullHouse,
  fourOfAKind,
  straightFlush;

  String get label {
    switch (this) {
      case HandRank.highCard:
        return 'High Card';
      case HandRank.pair:
        return 'Pair';
      case HandRank.twoPair:
        return 'Two Pair';
      case HandRank.threeOfAKind:
        return 'Three of a Kind';
      case HandRank.straight:
        return 'Straight';
      case HandRank.flush:
        return 'Flush';
      case HandRank.fullHouse:
        return 'Full House';
      case HandRank.fourOfAKind:
        return 'Four of a Kind';
      case HandRank.straightFlush:
        return 'Straight Flush';
    }
  }
}

class _Evaluation {
  const _Evaluation({
    required this.rank,
    required this.cards,
    required this.tiebreakers,
  });

  final HandRank rank;
  final Set<PlayingCard> cards;
  final List<int> tiebreakers;

  int compareTo(_Evaluation other) {
    final byRank = rank.index.compareTo(other.rank.index);
    if (byRank != 0) return byRank;
    final length = tiebreakers.length < other.tiebreakers.length
        ? tiebreakers.length
        : other.tiebreakers.length;
    for (var i = 0; i < length; i += 1) {
      final cmp = tiebreakers[i].compareTo(other.tiebreakers[i]);
      if (cmp != 0) return cmp;
    }
    return 0;
  }
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

    final evaluations = <_Evaluation>[];
    for (final playerCards in holeCards) {
      final seven = [...playerCards, ...board];
      evaluations.add(_evaluateSeven(seven));
    }

    var bestIndex = 0;
    for (var i = 1; i < evaluations.length; i += 1) {
      if (evaluations[i].compareTo(evaluations[bestIndex]) > 0) {
        bestIndex = i;
      }
    }
    final best = evaluations[bestIndex];

    final winnerIndexes = <int>{};
    final winningCardsByPlayer = <int, Set<PlayingCard>>{};
    final handLabelByPlayer = <int, String>{};
    for (var i = 0; i < evaluations.length; i += 1) {
      handLabelByPlayer[i] = evaluations[i].rank.label;
      if (evaluations[i].compareTo(best) == 0) {
        winnerIndexes.add(i);
        winningCardsByPlayer[i] = evaluations[i].cards;
      }
    }

    return ShowdownResult(
      winnerIndexes: winnerIndexes,
      winningCardsByPlayer: winningCardsByPlayer,
      handLabelByPlayer: handLabelByPlayer,
    );
  }

  _Evaluation _evaluateSeven(List<PlayingCard> cards) {
    final straightFlush = _findStraightFlush(cards);
    if (straightFlush != null) {
      final values = straightFlush.map((c) => c.rank.value).toList()
        ..sort((a, b) => b.compareTo(a));
      final high = _isWheel(values) ? 5 : values.first;
      return _Evaluation(
        rank: HandRank.straightFlush,
        cards: straightFlush,
        tiebreakers: [high],
      );
    }

    final byRank = _groupByRank(cards);
    final rankCounts = byRank.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.length.compareTo(a.value.length);
        if (byCount != 0) return byCount;
        return b.key.value.compareTo(a.key.value);
      });

    if (rankCounts.first.value.length >= 4) {
      final quadsRank = rankCounts.first.key;
      final quads = byRank[quadsRank]!.take(4).toList();
      final kicker = cards
          .where((c) => c.rank != quadsRank)
          .reduce((a, b) => a.rank.value > b.rank.value ? a : b);
      return _Evaluation(
        rank: HandRank.fourOfAKind,
        cards: {...quads, kicker},
        tiebreakers: [quadsRank.value, kicker.rank.value],
      );
    }

    final tripsRanks = rankCounts
        .where((entry) => entry.value.length >= 3)
        .map((entry) => entry.key)
        .toList();
    if (tripsRanks.isNotEmpty) {
      final tripRank = tripsRanks.first;
      final pairRanks = rankCounts
          .where((entry) => entry.key != tripRank && entry.value.length >= 2)
          .map((entry) => entry.key)
          .toList();
      if (pairRanks.isNotEmpty) {
        final pairRank = pairRanks.first;
        return _Evaluation(
          rank: HandRank.fullHouse,
          cards: {...byRank[tripRank]!.take(3), ...byRank[pairRank]!.take(2)},
          tiebreakers: [tripRank.value, pairRank.value],
        );
      }
    }

    final flushCards = _findFlush(cards);
    if (flushCards != null) {
      return _Evaluation(
        rank: HandRank.flush,
        cards: flushCards,
        tiebreakers: flushCards.map((c) => c.rank.value).toList()
          ..sort((a, b) => b.compareTo(a)),
      );
    }

    final straight = _findStraight(cards);
    if (straight != null) {
      final values = straight.map((c) => c.rank.value).toList()
        ..sort((a, b) => b.compareTo(a));
      final high = _isWheel(values) ? 5 : values.first;
      return _Evaluation(
        rank: HandRank.straight,
        cards: straight,
        tiebreakers: [high],
      );
    }

    if (tripsRanks.isNotEmpty) {
      final tripRank = tripsRanks.first;
      final kickers = cards.where((c) => c.rank != tripRank).toList()
        ..sort((a, b) => b.rank.value.compareTo(a.rank.value));
      final selectedKickers = kickers.take(2).toList();
      return _Evaluation(
        rank: HandRank.threeOfAKind,
        cards: {...byRank[tripRank]!.take(3), ...selectedKickers},
        tiebreakers: [
          tripRank.value,
          ...selectedKickers.map((c) => c.rank.value),
        ],
      );
    }

    final pairRanks = rankCounts
        .where((entry) => entry.value.length >= 2)
        .map((entry) => entry.key)
        .toList();
    if (pairRanks.length >= 2) {
      final highPair = pairRanks[0];
      final lowPair = pairRanks[1];
      final pairCards = [
        ...byRank[highPair]!.take(2),
        ...byRank[lowPair]!.take(2),
      ];
      final kicker = cards
          .where((c) => c.rank != highPair && c.rank != lowPair)
          .reduce((a, b) => a.rank.value > b.rank.value ? a : b);
      return _Evaluation(
        rank: HandRank.twoPair,
        cards: {...pairCards, kicker},
        tiebreakers: [highPair.value, lowPair.value, kicker.rank.value],
      );
    }

    if (pairRanks.length == 1) {
      final pairRank = pairRanks.first;
      final kickers = cards.where((c) => c.rank != pairRank).toList()
        ..sort((a, b) => b.rank.value.compareTo(a.rank.value));
      final selectedKickers = kickers.take(3).toList();
      return _Evaluation(
        rank: HandRank.pair,
        cards: {...byRank[pairRank]!.take(2), ...selectedKickers},
        tiebreakers: [
          pairRank.value,
          ...selectedKickers.map((c) => c.rank.value),
        ],
      );
    }

    final sorted = [...cards]
      ..sort((a, b) => b.rank.value.compareTo(a.rank.value));
    final top5 = sorted.take(5).toList();
    return _Evaluation(
      rank: HandRank.highCard,
      cards: top5.toSet(),
      tiebreakers: top5.map((c) => c.rank.value).toList(),
    );
  }

  Set<PlayingCard>? _findFlush(List<PlayingCard> cards) {
    for (final suit in CardSuit.values) {
      final ofSuit = cards.where((c) => c.suit == suit).toList()
        ..sort((a, b) => b.rank.value.compareTo(a.rank.value));
      if (ofSuit.length >= 5) {
        return ofSuit.take(5).toSet();
      }
    }
    return null;
  }

  Set<PlayingCard>? _findStraight(List<PlayingCard> cards) {
    final byValue = <int, PlayingCard>{};
    for (final card in cards) {
      byValue.putIfAbsent(card.rank.value, () => card);
      if (card.rank == CardRank.ace) {
        byValue.putIfAbsent(1, () => card);
      }
    }

    final values = byValue.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final high in values) {
      if (high < 5) break;
      final sequence = [for (var i = 0; i < 5; i += 1) high - i];
      if (sequence.every(byValue.containsKey)) {
        return sequence.map((value) => byValue[value]!).toSet();
      }
    }
    return null;
  }

  Set<PlayingCard>? _findStraightFlush(List<PlayingCard> cards) {
    for (final suit in CardSuit.values) {
      final ofSuit = cards.where((c) => c.suit == suit).toList();
      if (ofSuit.length < 5) continue;
      final straight = _findStraight(ofSuit);
      if (straight != null) return straight;
    }
    return null;
  }

  Map<CardRank, List<PlayingCard>> _groupByRank(List<PlayingCard> cards) {
    final result = <CardRank, List<PlayingCard>>{};
    for (final card in cards) {
      result.putIfAbsent(card.rank, () => []).add(card);
    }
    return result;
  }

  bool _isWheel(List<int> sortedDesc) {
    if (sortedDesc.length < 5) return false;
    return sortedDesc[0] == 5 &&
        sortedDesc[1] == 4 &&
        sortedDesc[2] == 3 &&
        sortedDesc[3] == 2 &&
        sortedDesc[4] == 1;
  }
}
