import 'package:flutter/material.dart';
import '../models/card_color_mode.dart';
import '../models/playing_card.dart';
import '../theme/tokens.dart';

/// How a full-size face is drawn.
enum CardFace {
  /// One rank character over one suit mark, readable at a glance.
  rankSuit,

  /// Traditional pips with no corner index, for the river squeeze where the
  /// rank must only show as the pips come into view.
  pips,
}

class PlayingCardView extends StatelessWidget {
  const PlayingCardView({
    super.key,
    this.card,
    required this.colorMode,
    this.faceDown = false,
    this.highlight = false,
    this.compact = false,
    this.face = CardFace.rankSuit,
    this.size,
  });

  final PlayingCard? card;
  final CardColorMode colorMode;
  final bool faceDown;
  final bool highlight;
  final bool compact;
  final CardFace face;
  final Size? size;

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
        child: isBack ? const _CardBack() : _face(card!),
      ),
    );
  }

  Widget _face(PlayingCard card) {
    // Compact hole cards share the board's rank-and-suit design.
    final Widget face = this.face == CardFace.pips && !compact
        ? _PipFace(card: card, colorMode: colorMode)
        : _IndexFace(card: card, colorMode: colorMode);
    // Read the card as words rather than as a run of suit symbols.
    return Semantics(
      label: '${card.rank.name} of ${card.suit.name}s',
      excludeSemantics: true,
      child: face,
    );
  }
}

class _IndexFace extends StatelessWidget {
  const _IndexFace({required this.card, required this.colorMode});

  final PlayingCard card;
  final CardColorMode colorMode;

  @override
  Widget build(BuildContext context) {
    final color = card.suit.color(colorMode);
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        TextStyle style(double size) => TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FlipoutType.cta,
          height: 1,
        );
        return Padding(
          padding: EdgeInsets.symmetric(vertical: h * 0.06),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(card.rankLabel, style: style(h * 0.48)),
                SizedBox(height: h * 0.02),
                Text(card.suitSymbol, style: style(h * 0.34)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PipFace extends StatelessWidget {
  const _PipFace({required this.card, required this.colorMode});

  final PlayingCard card;
  final CardColorMode colorMode;

  @override
  Widget build(BuildContext context) {
    final color = card.suit.color(colorMode);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.1,
            vertical: h * 0.08,
          ),
          child: _CardCenter(card: card, color: color),
        );
      },
    );
  }
}

class _CardCenter extends StatelessWidget {
  const _CardCenter({required this.card, required this.color});

  final PlayingCard card;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (card.rank == CardRank.ace) {
      return _AceCenter(suit: card.suitSymbol, color: color);
    }
    if (_isCourt(card.rank)) {
      return _CourtCenter(card: card, color: color);
    }
    return _PipLayout(rank: card.rank, suit: card.suitSymbol, color: color);
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
      child: FractionallySizedBox(
        widthFactor: 0.8,
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
      ),
    );
  }
}

class _CourtCenter extends StatelessWidget {
  const _CourtCenter({required this.card, required this.color});

  final PlayingCard card;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(2),
      ),
      // A FittedBox under tight constraints scales up as well as down, so
      // the court index fills large faces such as the squeeze card.
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
    );
  }
}

class _PipLayout extends StatelessWidget {
  const _PipLayout({
    required this.rank,
    required this.suit,
    required this.color,
  });

  final CardRank rank;
  final String suit;
  final Color color;

  /// Horizontal position of the outer pip columns. With no corner index
  /// they sit close to the long edges, so a side squeeze reaches them early.
  static const _side = 0.8;

  static const Map<CardRank, List<_Pip>> _layout = {
    CardRank.two: [_Pip(0, -0.85), _Pip(0, 0.85, flipped: true)],
    CardRank.three: [_Pip(0, -0.85), _Pip(0, 0), _Pip(0, 0.85, flipped: true)],
    CardRank.four: [
      _Pip(-_side, -0.85),
      _Pip(_side, -0.85),
      _Pip(-_side, 0.85, flipped: true),
      _Pip(_side, 0.85, flipped: true),
    ],
    CardRank.five: [
      _Pip(-_side, -0.85),
      _Pip(_side, -0.85),
      _Pip(0, 0),
      _Pip(-_side, 0.85, flipped: true),
      _Pip(_side, 0.85, flipped: true),
    ],
    CardRank.six: [
      _Pip(-_side, -0.85),
      _Pip(_side, -0.85),
      _Pip(-_side, 0),
      _Pip(_side, 0),
      _Pip(-_side, 0.85, flipped: true),
      _Pip(_side, 0.85, flipped: true),
    ],
    CardRank.seven: [
      _Pip(-_side, -0.85),
      _Pip(_side, -0.85),
      _Pip(0, -0.42),
      _Pip(-_side, 0),
      _Pip(_side, 0),
      _Pip(-_side, 0.85, flipped: true),
      _Pip(_side, 0.85, flipped: true),
    ],
    CardRank.eight: [
      _Pip(-_side, -0.85),
      _Pip(_side, -0.85),
      _Pip(0, -0.42),
      _Pip(-_side, 0),
      _Pip(_side, 0),
      _Pip(0, 0.42, flipped: true),
      _Pip(-_side, 0.85, flipped: true),
      _Pip(_side, 0.85, flipped: true),
    ],
    CardRank.nine: [
      _Pip(-_side, -0.85),
      _Pip(_side, -0.85),
      _Pip(-_side, -0.3),
      _Pip(_side, -0.3),
      _Pip(0, 0),
      _Pip(-_side, 0.3, flipped: true),
      _Pip(_side, 0.3, flipped: true),
      _Pip(-_side, 0.85, flipped: true),
      _Pip(_side, 0.85, flipped: true),
    ],
    CardRank.ten: [
      _Pip(-_side, -0.85),
      _Pip(_side, -0.85),
      _Pip(0, -0.55),
      _Pip(-_side, -0.25),
      _Pip(_side, -0.25),
      _Pip(-_side, 0.25, flipped: true),
      _Pip(_side, 0.25, flipped: true),
      _Pip(0, 0.55, flipped: true),
      _Pip(-_side, 0.85, flipped: true),
      _Pip(_side, 0.85, flipped: true),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final pips = _layout[rank] ?? const [];
    return LayoutBuilder(
      builder: (context, c) {
        final pipSize = c.maxWidth * 0.34;
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
