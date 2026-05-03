import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/playing_card.dart';
import '../models/settings.dart';
import 'playing_card_view.dart';

class RiverSqueezeCard extends StatefulWidget {
  const RiverSqueezeCard({
    super.key,
    required this.card,
    required this.progress,
    required this.onProgress,
    required this.onRelease,
  });

  final PlayingCard card;
  final double progress;
  final ValueChanged<double> onProgress;
  final VoidCallback onRelease;

  @override
  State<RiverSqueezeCard> createState() => _RiverSqueezeCardState();
}

class _RiverSqueezeCardState extends State<RiverSqueezeCard> {
  bool _thresholdBuzzed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        final delta = (details.delta.dx.abs() + details.delta.dy.abs()) / 150;
        final next = (widget.progress + delta).clamp(0.0, 1.0);
        if (next >= 0.55 && !_thresholdBuzzed) {
          _thresholdBuzzed = true;
          HapticFeedback.selectionClick();
        }
        widget.onProgress(next);
      },
      onPanEnd: (_) {
        _thresholdBuzzed = false;
        widget.onRelease();
      },
      onPanCancel: () {
        _thresholdBuzzed = false;
        widget.onRelease();
      },
      child: AspectRatio(
        aspectRatio: 0.72,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const PlayingCardView.back(),
            ClipPath(
              clipper: _CornerRevealClipper(widget.progress),
              child: PlayingCardView(
                card: widget.card,
                colorMode: CardColorMode.twoColor,
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Icon(
                Icons.swipe_down_alt,
                size: 18,
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerRevealClipper extends CustomClipper<Path> {
  const _CornerRevealClipper(this.progress);

  final double progress;

  @override
  Path getClip(Size size) {
    final p = progress.clamp(0, 1);
    final width = size.width * (0.18 + p * 0.82);
    final height = size.height * (0.18 + p * 0.82);

    return Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, height)
      ..quadraticBezierTo(
        size.width - width * 0.36,
        height * 0.55,
        size.width - width,
        0,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant _CornerRevealClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}
