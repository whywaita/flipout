import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'card_color_mode.dart';

enum CardSuit {
  spade('s', '♠'),
  heart('h', '♥'),
  diamond('d', '♦'),
  club('c', '♣');

  const CardSuit(this.code, this.symbol);

  final String code;
  final String symbol;

  static CardSuit parse(String code) {
    return CardSuit.values.firstWhere((suit) => suit.code == code);
  }

  Color color(CardColorMode mode) {
    if (mode == CardColorMode.twoColor) {
      return this == CardSuit.heart || this == CardSuit.diamond
          ? FlipoutColors.suitRed
          : FlipoutColors.suitBlack;
    }

    switch (this) {
      case CardSuit.spade:
        return FlipoutColors.suitBlack;
      case CardSuit.heart:
        return FlipoutColors.suitRed;
      case CardSuit.diamond:
        return FlipoutColors.suitBlue;
      case CardSuit.club:
        return FlipoutColors.suitGreen;
    }
  }
}

enum CardRank {
  ace('A', 14),
  two('2', 2),
  three('3', 3),
  four('4', 4),
  five('5', 5),
  six('6', 6),
  seven('7', 7),
  eight('8', 8),
  nine('9', 9),
  ten('T', 10),
  jack('J', 11),
  queen('Q', 12),
  king('K', 13);

  const CardRank(this.code, this.value);

  final String code;
  final int value;

  static CardRank parse(String code) {
    return CardRank.values.firstWhere((rank) => rank.code == code);
  }
}

@immutable
class PlayingCard {
  const PlayingCard({required this.rank, required this.suit});

  factory PlayingCard.parse(String code) {
    if (!RegExp(r'^[A23456789TJQK][shdc]$').hasMatch(code)) {
      throw FormatException('Invalid card code', code);
    }

    return PlayingCard(
      rank: CardRank.parse(code[0]),
      suit: CardSuit.parse(code[1]),
    );
  }

  final CardRank rank;
  final CardSuit suit;

  String get code => '${rank.code}${suit.code}';
  String get rankLabel => rank.code;
  String get suitSymbol => suit.symbol;

  static List<PlayingCard> standardDeck() {
    return [
      for (final suit in CardSuit.values)
        for (final rank in CardRank.values) PlayingCard(rank: rank, suit: suit),
    ];
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
