import 'package:flutter/material.dart';
import '../models/card_color_mode.dart';
import '../models/playing_card.dart';
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
        width: 112,
        height: 148,
        child: Stack(
          children: [
            Positioned.fill(
              child: PlayingCardView(
                card: widget.card,
                colorMode: widget.colorMode,
                faceDown: true,
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              width: 34 + _liveProgress * 70,
              height: 34 + _liveProgress * 86,
              child: ClipPath(
                clipper: _SqueezeClipper(_liveProgress),
                child: _RevealedCorner(card: widget.card),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Text(
                '${(_liveProgress * 100).round()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xfffffbeb),
                  fontWeight: FontWeight.w700,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Align(
          alignment: Alignment.topLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.rankLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                Text(
                  card.suitSymbol,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
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
