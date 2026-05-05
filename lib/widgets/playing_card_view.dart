import 'dart:math' as math;

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
    this.size,
    this.stripped = false,
  });

  final PlayingCard? card;
  final CardColorMode colorMode;
  final bool faceDown;
  final bool highlight;
  final bool compact;
  final Size? size;

  /// When true, drops the corner rank/suit indices and lets the centre pip
  /// layout fill the card. Used by the squeeze view so that peeling shows
  /// the largest possible suit shape.
  final bool stripped;

  @override
  Widget build(BuildContext context) {
    final resolved =
        size ?? (compact ? const Size(40, 56) : const Size(56, 78));
    final isBack = faceDown || card == null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: resolved.width,
      height: resolved.height,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 4 : FlipoutRadius.sm),
        child: isBack
            ? const _CardBack()
            : compact
            ? _CompactFace(card: card!, colorMode: colorMode)
            : _DetailedFace(
                card: card!,
                colorMode: colorMode,
                stripped: stripped,
              ),
      ),
    );
  }
}

class _CompactFace extends StatelessWidget {
  const _CompactFace({required this.card, required this.colorMode});

  final PlayingCard card;
  final CardColorMode colorMode;

  @override
  Widget build(BuildContext context) {
    final color = card.suit.color(colorMode);
    final rankStyle = TextStyle(
      color: color,
      fontWeight: FlipoutType.cta,
      fontSize: FlipoutType.sm,
      height: 1,
    );

    return Stack(
      children: [
        Positioned(
          left: 4,
          top: 2,
          child: Text(card.rankLabel, style: rankStyle),
        ),
        Positioned(
          left: 4,
          top: 16,
          child: Text(card.suitSymbol, style: rankStyle.copyWith(fontSize: 10)),
        ),
        Positioned.fill(
          child: Center(
            child: Text(
              card.suitSymbol,
              style: rankStyle.copyWith(
                fontSize: 14,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailedFace extends StatelessWidget {
  const _DetailedFace({
    required this.card,
    required this.colorMode,
    this.stripped = false,
  });

  final PlayingCard card;
  final CardColorMode colorMode;
  final bool stripped;

  @override
  Widget build(BuildContext context) {
    final color = card.suit.color(colorMode);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cornerScale = w / 56;
        final cornerSize = (FlipoutType.md * cornerScale).clamp(11.0, 28.0);
        final suitSize = (cornerSize * 0.85);

        final centerPadding = stripped
            ? EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.06)
            : EdgeInsets.symmetric(horizontal: w * 0.18, vertical: h * 0.16);

        return Stack(
          children: [
            if (!stripped) ...[
              Positioned(
                left: w * 0.05,
                top: h * 0.04,
                child: _CornerIndex(
                  rank: card.rankLabel,
                  suit: card.suitSymbol,
                  color: color,
                  rankSize: cornerSize,
                  suitSize: suitSize,
                ),
              ),
              Positioned(
                right: w * 0.05,
                bottom: h * 0.04,
                child: Transform.rotate(
                  angle: math.pi,
                  child: _CornerIndex(
                    rank: card.rankLabel,
                    suit: card.suitSymbol,
                    color: color,
                    rankSize: cornerSize,
                    suitSize: suitSize,
                  ),
                ),
              ),
            ],
            Positioned.fill(
              child: Padding(
                padding: centerPadding,
                child: _CardCenter(
                  card: card,
                  color: color,
                  stripped: stripped,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CornerIndex extends StatelessWidget {
  const _CornerIndex({
    required this.rank,
    required this.suit,
    required this.color,
    required this.rankSize,
    required this.suitSize,
  });

  final String rank;
  final String suit;
  final Color color;
  final double rankSize;
  final double suitSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          rank,
          style: TextStyle(
            color: color,
            fontSize: rankSize,
            fontWeight: FlipoutType.cta,
            height: 1,
          ),
        ),
        SizedBox(height: rankSize * 0.05),
        Text(
          suit,
          style: TextStyle(
            color: color,
            fontSize: suitSize,
            fontWeight: FlipoutType.cta,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _CardCenter extends StatelessWidget {
  const _CardCenter({
    required this.card,
    required this.color,
    this.stripped = false,
  });

  final PlayingCard card;
  final Color color;
  final bool stripped;

  @override
  Widget build(BuildContext context) {
    if (card.rank == CardRank.ace) {
      return _AceCenter(suit: card.suitSymbol, color: color);
    }
    if (_isCourt(card.rank)) {
      return _CourtCenter(card: card, color: color, stripped: stripped);
    }
    return _PipLayout(
      rank: card.rank,
      suit: card.suitSymbol,
      color: color,
      stripped: stripped,
    );
  }

  bool _isCourt(CardRank rank) =>
      rank == CardRank.jack || rank == CardRank.queen || rank == CardRank.king;
}

class _AceCenter extends StatelessWidget {
  const _AceCenter({required this.suit, required this.color});

  final String suit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        child: Text(
          suit,
          style: TextStyle(
            color: color,
            fontWeight: FlipoutType.cta,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _CourtCenter extends StatelessWidget {
  const _CourtCenter({
    required this.card,
    required this.color,
    this.stripped = false,
  });

  final PlayingCard card;
  final Color color;
  final bool stripped;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.rankLabel,
                  style: TextStyle(
                    color: color,
                    fontWeight: FlipoutType.cta,
                    height: 1,
                    fontSize: 36,
                  ),
                ),
                Text(
                  card.suitSymbol,
                  style: TextStyle(
                    color: color,
                    fontWeight: FlipoutType.cta,
                    height: 1,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PipLayout extends StatelessWidget {
  const _PipLayout({
    required this.rank,
    required this.suit,
    required this.color,
    this.stripped = false,
  });

  final CardRank rank;
  final String suit;
  final Color color;
  final bool stripped;

  static const Map<CardRank, List<_Pip>> _layout = {
    CardRank.two: [_Pip(0, -0.85), _Pip(0, 0.85, flipped: true)],
    CardRank.three: [_Pip(0, -0.85), _Pip(0, 0), _Pip(0, 0.85, flipped: true)],
    CardRank.four: [
      _Pip(-0.55, -0.85),
      _Pip(0.55, -0.85),
      _Pip(-0.55, 0.85, flipped: true),
      _Pip(0.55, 0.85, flipped: true),
    ],
    CardRank.five: [
      _Pip(-0.55, -0.85),
      _Pip(0.55, -0.85),
      _Pip(0, 0),
      _Pip(-0.55, 0.85, flipped: true),
      _Pip(0.55, 0.85, flipped: true),
    ],
    CardRank.six: [
      _Pip(-0.55, -0.85),
      _Pip(0.55, -0.85),
      _Pip(-0.55, 0),
      _Pip(0.55, 0),
      _Pip(-0.55, 0.85, flipped: true),
      _Pip(0.55, 0.85, flipped: true),
    ],
    CardRank.seven: [
      _Pip(-0.55, -0.85),
      _Pip(0.55, -0.85),
      _Pip(0, -0.42),
      _Pip(-0.55, 0),
      _Pip(0.55, 0),
      _Pip(-0.55, 0.85, flipped: true),
      _Pip(0.55, 0.85, flipped: true),
    ],
    CardRank.eight: [
      _Pip(-0.55, -0.85),
      _Pip(0.55, -0.85),
      _Pip(0, -0.42),
      _Pip(-0.55, 0),
      _Pip(0.55, 0),
      _Pip(0, 0.42, flipped: true),
      _Pip(-0.55, 0.85, flipped: true),
      _Pip(0.55, 0.85, flipped: true),
    ],
    CardRank.nine: [
      _Pip(-0.55, -0.85),
      _Pip(0.55, -0.85),
      _Pip(-0.55, -0.3),
      _Pip(0.55, -0.3),
      _Pip(0, 0),
      _Pip(-0.55, 0.3, flipped: true),
      _Pip(0.55, 0.3, flipped: true),
      _Pip(-0.55, 0.85, flipped: true),
      _Pip(0.55, 0.85, flipped: true),
    ],
    CardRank.ten: [
      _Pip(-0.55, -0.85),
      _Pip(0.55, -0.85),
      _Pip(0, -0.55),
      _Pip(-0.55, -0.25),
      _Pip(0.55, -0.25),
      _Pip(-0.55, 0.25, flipped: true),
      _Pip(0.55, 0.25, flipped: true),
      _Pip(0, 0.55, flipped: true),
      _Pip(-0.55, 0.85, flipped: true),
      _Pip(0.55, 0.85, flipped: true),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final pips = _layout[rank] ?? const [];
    return LayoutBuilder(
      builder: (context, c) {
        final pipSize = c.maxWidth * (stripped ? 0.2 : 0.34);
        return Stack(
          children: [
            for (final pip in pips)
              Align(
                alignment: Alignment(pip.x, pip.y),
                child: Transform.scale(
                  scaleY: pip.flipped ? -1 : 1,
                  child: Text(
                    suit,
                    style: TextStyle(
                      color: color,
                      fontSize: pipSize,
                      fontWeight: FlipoutType.cta,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Pip {
  const _Pip(this.x, this.y, {this.flipped = false});

  final double x;
  final double y;
  final bool flipped;
}

class _CardBack extends StatelessWidget {
  const _CardBack();

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
      child: LayoutBuilder(
        builder: (context, c) {
          final inset = c.maxWidth * 0.08;
          return Padding(
            padding: EdgeInsets.all(inset),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(c.maxWidth * 0.06),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.4,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.diamond_outlined,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: c.maxWidth * 0.35,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
