import 'package:flutter/material.dart';
import '../models/card_color_mode.dart';
import '../models/playing_card.dart';
import '../theme/tokens.dart';
import 'playing_card_view.dart';

class RiverSqueezeCard extends StatefulWidget {
  const RiverSqueezeCard({
    super.key,
    required this.card,
    required this.colorMode,
    required this.progress,
    required this.onProgress,
    required this.onRelease,
  });

  final PlayingCard card;
  final CardColorMode colorMode;
  final double progress;
  final ValueChanged<double> onProgress;
  final ValueChanged<double> onRelease;

  @override
  State<RiverSqueezeCard> createState() => _RiverSqueezeCardState();
}

class _RiverSqueezeCardState extends State<RiverSqueezeCard> {
  late double _liveProgress;

  @override
  void initState() {
    super.initState();
    _liveProgress = widget.progress;
  }

  @override
  void didUpdateWidget(covariant RiverSqueezeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _liveProgress = widget.progress;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('riverSqueeze'),
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        final delta = (details.delta.dx + details.delta.dy) / 260;
        setState(() {
          _liveProgress = (_liveProgress + delta).clamp(0, 1).toDouble();
        });
        widget.onProgress(_liveProgress);
      },
      onPanEnd: (_) => widget.onRelease(_liveProgress),
      child: SizedBox(
        width: 96,
        height: 132,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(FlipoutRadius.sm),
                  boxShadow: FlipoutShadows.shadow2,
                ),
                child: PlayingCardView(
                  card: widget.card,
                  colorMode: widget.colorMode,
                  faceDown: true,
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              width: 30 + _liveProgress * 66,
              height: 30 + _liveProgress * 84,
              child: ClipPath(
                clipper: _SqueezeClipper(_liveProgress),
                child: _RevealedCorner(card: widget.card),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FlipoutSpace.s1,
                    vertical: 2,
                  ),
                  child: Text(
                    '${(_liveProgress * 100).round()}%',
                    style: const TextStyle(
                      color: FlipoutColors.accentInk,
                      fontSize: FlipoutType.xs,
                      fontWeight: FlipoutType.cta,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealedCorner extends StatelessWidget {
  const _RevealedCorner({required this.card});

  final PlayingCard card;

  @override
  Widget build(BuildContext context) {
    final color = card.suit.color(CardColorMode.twoColor);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlipoutColors.cardBg,
        borderRadius: BorderRadius.circular(FlipoutRadius.sm),
        border: Border.all(color: FlipoutColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FlipoutSpace.s2),
        child: Align(
          alignment: Alignment.topLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.rankLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FlipoutType.cta,
                    height: 1,
                  ),
                ),
                Text(
                  card.suitSymbol,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FlipoutType.cta,
                    height: 1,
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

class _SqueezeClipper extends CustomClipper<Path> {
  const _SqueezeClipper(this.progress);

  final double progress;

  @override
  Path getClip(Size size) {
    final pull = progress.clamp(0.08, 1).toDouble();
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * pull, 0)
      ..quadraticBezierTo(
        size.width * 0.74,
        size.height * 0.24,
        size.width,
        size.height * pull,
      )
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant _SqueezeClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}
