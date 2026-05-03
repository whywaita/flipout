import 'package:flutter/material.dart';
import '../models/card_color_mode.dart';
import '../models/playing_card.dart';

class PlayingCardView extends StatelessWidget {
  const PlayingCardView({
    super.key,
    this.card,
    required this.colorMode,
    this.faceDown = false,
    this.highlight = false,
    this.compact = false,
  });

  final PlayingCard? card;
  final CardColorMode colorMode;
  final bool faceDown;
  final bool highlight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 42.0 : 56.0;
    final height = compact ? 60.0 : 78.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: faceDown || card == null
            ? const Color(0xff7f1d1d)
            : Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: highlight ? const Color(0xffffc857) : const Color(0xffd1d5db),
          width: highlight ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: faceDown || card == null
          ? _CardBack(compact: compact)
          : _Face(card: card!, colorMode: colorMode, compact: compact),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({
    required this.card,
    required this.colorMode,
    required this.compact,
  });

  final PlayingCard card;
  final CardColorMode colorMode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = card.suit.color(colorMode);
    final labelStyle = TextStyle(
      color: color,
      fontWeight: FontWeight.w800,
      fontSize: compact ? 16 : 20,
      height: 1,
    );

    final inset = compact ? 5.0 : 7.0;
    return Stack(
      children: [
        Positioned(
          left: inset,
          top: inset,
          child: Text(card.rankLabel, style: labelStyle),
        ),
        Positioned(
          left: inset,
          top: compact ? 20 : 25,
          child: Text(
            card.suitSymbol,
            style: labelStyle.copyWith(fontSize: compact ? 12 : 16),
          ),
        ),
        Positioned(
          right: inset,
          bottom: inset,
          child: Text(
            card.suitSymbol,
            style: labelStyle.copyWith(fontSize: compact ? 18 : 24),
          ),
        ),
      ],
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(compact ? 5 : 7),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xfffffbeb), width: 2),
        ),
        child: Center(
          child: Icon(
            Icons.auto_awesome,
            color: const Color(0xfffffbeb),
            size: compact ? 18 : 24,
          ),
        ),
      ),
    );
  }
}
