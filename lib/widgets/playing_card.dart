import 'package:flutter/material.dart' hide Card;
import 'package:poker/poker.dart';
import '../models/settings.dart';

/// Widget to display a playing card
class PlayingCard extends StatelessWidget {
  final Card card;
  final bool isHighlighted;
  final CardColorMode colorMode;
  final double width;
  final double height;

  const PlayingCard({
    Key? key,
    required this.card,
    this.isHighlighted = false,
    this.colorMode = CardColorMode.fourColor,
    this.width = 60,
    this.height = 84,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted ? Colors.amber : Colors.black26,
          width: isHighlighted ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _rankToString(card.rank),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _getCardColor(card.suit),
            ),
          ),
          Text(
            _suitToSymbol(card.suit),
            style: TextStyle(
              fontSize: 28,
              color: _getCardColor(card.suit),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCardColor(Suit suit) {
    if (colorMode == CardColorMode.fourColor) {
      switch (suit) {
        case Suit.spade:
          return Colors.black;
        case Suit.heart:
          return Colors.red;
        case Suit.diamond:
          return Colors.blue;
        case Suit.club:
          return Colors.green;
      }
    } else {
      // 2-color mode
      switch (suit) {
        case Suit.spade:
        case Suit.club:
          return Colors.black;
        case Suit.heart:
        case Suit.diamond:
          return Colors.red;
      }
    }
  }

  String _rankToString(Rank rank) {
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

  String _suitToSymbol(Suit suit) {
    switch (suit) {
      case Suit.spade:
        return '♠';
      case Suit.heart:
        return '♥';
      case Suit.diamond:
        return '♦';
      case Suit.club:
        return '♣';
    }
  }
}

/// Widget to display a card back
class CardBack extends StatelessWidget {
  final double width;
  final double height;

  const CardBack({
    Key? key,
    this.width = 60,
    this.height = 84,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.blue.shade800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black26, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.style,
          color: Colors.white.withValues(alpha: 0.3),
          size: 40,
        ),
      ),
    );
  }
}
