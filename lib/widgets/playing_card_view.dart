import 'package:flutter/material.dart';
import '../models/card_color_mode.dart';
import '../models/playing_card.dart';
import '../theme/tokens.dart';

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
    final width = compact ? 40.0 : 56.0;
    final height = compact ? 56.0 : 78.0;
    final isBack = faceDown || card == null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isBack ? FlipoutColors.cardBackA : FlipoutColors.cardBg,
        borderRadius: BorderRadius.circular(compact ? 4 : FlipoutRadius.sm),
        border: Border.all(
          color: highlight
              ? FlipoutColors.winner
              : isBack
              ? FlipoutColors.accentHover
              : FlipoutColors.cardBorder,
          width: highlight ? 2 : 1,
        ),
        boxShadow: highlight
            ? const [
                BoxShadow(
                  color: Color(0x40b45309),
                  offset: Offset(0, 4),
                  blurRadius: 12,
                ),
              ]
            : FlipoutShadows.shadow1,
      ),
      child: isBack
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
    final rankStyle = TextStyle(
      color: color,
      fontWeight: FlipoutType.cta,
      fontSize: compact ? FlipoutType.sm : FlipoutType.md,
      height: 1,
    );

    final inset = compact ? 4.0 : 6.0;
    return Stack(
      children: [
        Positioned(
          left: inset,
          top: inset,
          child: Text(card.rankLabel, style: rankStyle),
        ),
        Positioned(
          left: inset,
          top: compact ? 16 : 20,
          child: Text(
            card.suitSymbol,
            style: rankStyle.copyWith(fontSize: compact ? 10 : FlipoutType.sm),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Text(
              card.suitSymbol,
              style: rankStyle.copyWith(
                fontSize: compact ? 14 : 26,
                color: color.withValues(alpha: 0.9),
              ),
            ),
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FlipoutColors.cardBackA, FlipoutColors.cardBackB],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 4 : 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 3 : 4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.diamond_outlined,
              color: Colors.white.withValues(alpha: 0.85),
              size: compact ? 14 : 22,
            ),
          ),
        ),
      ),
    );
  }
}
