import 'package:poker/poker.dart' as poker;

enum PlayingCardRank {
  ace('A', 14),
  king('K', 13),
  queen('Q', 12),
  jack('J', 11),
  ten('T', 10),
  nine('9', 9),
  eight('8', 8),
  seven('7', 7),
  six('6', 6),
  five('5', 5),
  four('4', 4),
  trey('3', 3),
  deuce('2', 2);

  const PlayingCardRank(this.code, this.value);

  final String code;
  final int value;

  static PlayingCardRank parse(String code) {
    for (final rank in values) {
      if (rank.code == code) {
        return rank;
      }
    }
    throw FormatException('Invalid rank: $code');
  }
}

enum PlayingCardSuit {
  spade('s', '♠'),
  heart('h', '♥'),
  diamond('d', '♦'),
  club('c', '♣');

  const PlayingCardSuit(this.code, this.symbol);

  final String code;
  final String symbol;

  bool get isRed => this == heart || this == diamond;

  static PlayingCardSuit parse(String code) {
    for (final suit in values) {
      if (suit.code == code) {
        return suit;
      }
    }
    throw FormatException('Invalid suit: $code');
  }
}

class PlayingCard implements Comparable<PlayingCard> {
  const PlayingCard({required this.rank, required this.suit});

  factory PlayingCard.parse(String code) {
    if (code.length != 2) {
      throw FormatException('Invalid card: $code');
    }

    return PlayingCard(
      rank: PlayingCardRank.parse(code[0]),
      suit: PlayingCardSuit.parse(code[1]),
    );
  }

  final PlayingCardRank rank;
  final PlayingCardSuit suit;

  String get code => '${rank.code}${suit.code}';

  String get rankLabel => rank.code == 'T' ? '10' : rank.code;

  poker.Card toPokerCard() {
    return poker.Card(poker.Rank.parse(rank.code), poker.Suit.parse(suit.code));
  }

  @override
  int compareTo(PlayingCard other) {
    final suitCompare = suit.index.compareTo(other.suit.index);
    if (suitCompare != 0) {
      return suitCompare;
    }
    return other.rank.value.compareTo(rank.value);
  }

  @override
  String toString() => code;

  @override
  bool operator ==(Object other) {
    return other is PlayingCard && other.rank == rank && other.suit == suit;
  }

  @override
  int get hashCode => Object.hash(rank, suit);
}
