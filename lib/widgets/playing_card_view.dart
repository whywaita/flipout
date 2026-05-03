import 'package:flutter/material.dart';

import '../models/playing_card.dart';
import '../models/settings.dart';

class PlayingCardView extends StatelessWidget {
  const PlayingCardView({
    super.key,
    required this.card,
    required this.colorMode,
    this.highlighted = false,
    this.compact = false,
  }) : faceDown = false;

  const PlayingCardView.empty({super.key, this.compact = false})
    : card = null,
      colorMode = CardColorMode.twoColor,
      highlighted = false,
      faceDown = false;

  const PlayingCardView.back({super.key, this.compact = false})
    : card = null,
      colorMode = CardColorMode.twoColor,
      highlighted = false,
      faceDown = true;

  final PlayingCard? card;
  final CardColorMode colorMode;
  final bool highlighted;
  final bool compact;
  final bool faceDown;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6);
    final card = this.card;

    return AspectRatio(
      aspectRatio: 0.72,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: faceDown
              ? const Color(0xFF19314F)
              : card == null
              ? const Color(0xFFE6E1D8)
              : Colors.white,
          borderRadius: radius,
          border: Border.all(
            color: highlighted ? const Color(0xFFE1A526) : Colors.black12,
            width: highlighted ? 3 : 1,
          ),
          boxShadow: [
            if (!compact)
              const BoxShadow(
                color: Color(0x33000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: card == null
              ? _EmptyCard(faceDown: faceDown)
              : _FaceCard(
                  card: card,
                  color: suitColor(card, colorMode),
                  compact: compact,
                ),
        ),
      ),
    );
  }
}

class _FaceCard extends StatelessWidget {
  const _FaceCard({
    required this.card,
    required this.color,
    required this.compact,
  });

  final PlayingCard card;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(compact ? 4 : 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              card.rankLabel,
              style: TextStyle(
                color: color,
                fontSize: compact ? 18 : 24,
                height: 0.95,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            card.suit.symbol,
            style: TextStyle(
              color: color,
              fontSize: compact ? 15 : 22,
              height: 0.9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: RotatedBox(
              quarterTurns: 2,
              child: Text(
                card.suit.symbol,
                style: TextStyle(
                  color: color,
                  fontSize: compact ? 14 : 20,
                  height: 0.9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.faceDown});

  final bool faceDown;

  @override
  Widget build(BuildContext context) {
    if (!faceDown) {
      return const SizedBox.expand();
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF243D63), Color(0xFF10213A)],
        ),
      ),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white54, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const SizedBox(width: 26, height: 38),
        ),
      ),
    );
  }
}

Color suitColor(PlayingCard card, CardColorMode mode) {
  if (mode == CardColorMode.fourColor) {
    return switch (card.suit) {
      PlayingCardSuit.spade => const Color(0xFF202124),
      PlayingCardSuit.heart => const Color(0xFFC62828),
      PlayingCardSuit.diamond => const Color(0xFF1565C0),
      PlayingCardSuit.club => const Color(0xFF2E7D32),
    };
  }

  return card.suit.isRed ? const Color(0xFFC62828) : const Color(0xFF202124);
}
