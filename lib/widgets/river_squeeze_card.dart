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

class _RiverSqueezeCardState extends State<RiverSqueezeCard>
    with SingleTickerProviderStateMixin {
  static const Duration _squeezeDuration = Duration(milliseconds: 1800);
  static const Duration _releaseDuration = Duration(milliseconds: 320);

  late final AnimationController _controller;
  bool _isLandscape = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _squeezeDuration,
      reverseDuration: _releaseDuration,
      lowerBound: 0,
      upperBound: 1,
      value: widget.progress,
    );
    _controller.addListener(_handleTick);
    _controller.addStatusListener(_handleStatus);
  }

  void _handleTick() {
    widget.onProgress(_controller.value);
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_completed) {
      _completed = true;
      widget.onRelease(1);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTick);
    _controller.removeStatusListener(_handleStatus);
    _controller.dispose();
    super.dispose();
  }

  void _startSqueeze() {
    if (_completed) return;
    _controller.duration = _squeezeDuration;
    _controller.forward();
  }

  void _endSqueeze() {
    if (_completed) return;
    _controller.reverseDuration = _releaseDuration;
    _controller.reverse();
  }

  void _toggleOrientation() {
    if (_completed) return;
    setState(() => _isLandscape = !_isLandscape);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: AnimatedRotation(
            key: ValueKey(_isLandscape),
            turns: _isLandscape ? 0.25 : 0,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            child: SizedBox(
              width: 180,
              height: 252,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => _SqueezeStage(
                  card: widget.card,
                  colorMode: widget.colorMode,
                  progress: _controller.value,
                  isLandscape: _isLandscape,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: FlipoutSpace.s5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ControlButton(
              key: const Key('rotateButton'),
              icon: Icons.screen_rotation,
              label: _isLandscape ? 'TOP' : 'SIDE',
              onTap: _toggleOrientation,
            ),
            const SizedBox(width: FlipoutSpace.s4),
            _SqueezeButton(
              onPressStart: _startSqueeze,
              onPressEnd: _endSqueeze,
              progress: _controller.value,
            ),
          ],
        ),
        const SizedBox(height: FlipoutSpace.s2),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Text(
            '${(_controller.value * 100).round()}%',
            style: const TextStyle(
              color: FlipoutColors.textMuted,
              fontWeight: FlipoutType.cta,
              fontSize: FlipoutType.sm,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _SqueezeStage extends StatelessWidget {
  const _SqueezeStage({
    required this.card,
    required this.colorMode,
    required this.progress,
    required this.isLandscape,
  });

  final PlayingCard card;
  final CardColorMode colorMode;
  final double progress;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FlipoutRadius.sm + 2),
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            PlayingCardView(
              card: card,
              colorMode: colorMode,
              faceDown: false,
              size: const Size(180, 252),
              stripped: true,
            ),
            ClipPath(
              clipper: _PeelClipper(progress, isLandscape: isLandscape),
              child: PlayingCardView(
                card: card,
                colorMode: colorMode,
                faceDown: true,
                size: const Size(180, 252),
              ),
            ),
            ClipPath(
              clipper: _PeelEdgeClipper(progress, isLandscape: isLandscape),
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Color(0x33000000)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Defines the area that should remain face-down (covered by the back).
///
/// In portrait we reveal upward from the bottom edge. In landscape the card
/// itself has been rotated 90° clockwise, so the screen's bottom edge maps
/// to the card's right edge — we reveal leftward from that side.
class _PeelClipper extends CustomClipper<Path> {
  const _PeelClipper(this.progress, {required this.isLandscape});

  final double progress;
  final bool isLandscape;

  @override
  Path getClip(Size size) {
    final reveal = progress.clamp(0.0, 1.0);
    final path = Path();
    if (isLandscape) {
      final cutWidth = size.width * reveal;
      path
        ..moveTo(0, 0)
        ..lineTo(size.width - cutWidth, 0)
        ..lineTo(size.width - cutWidth, size.height)
        ..lineTo(0, size.height)
        ..close();
    } else {
      final cutHeight = size.height * reveal;
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height - cutHeight)
        ..lineTo(0, size.height - cutHeight)
        ..close();
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _PeelClipper oldClipper) =>
      oldClipper.progress != progress || oldClipper.isLandscape != isLandscape;
}

/// Thin shadow band along the peel edge to give a "lifted paper" hint.
class _PeelEdgeClipper extends CustomClipper<Path> {
  const _PeelEdgeClipper(this.progress, {required this.isLandscape});

  final double progress;
  final bool isLandscape;

  @override
  Path getClip(Size size) {
    final reveal = progress.clamp(0.0, 1.0);
    if (reveal <= 0.001) return Path();
    final path = Path();
    if (isLandscape) {
      final x = size.width - size.width * reveal;
      path
        ..moveTo(x - 1, 0)
        ..lineTo(x + 4, 0)
        ..lineTo(x + 4, size.height)
        ..lineTo(x - 1, size.height)
        ..close();
    } else {
      final y = size.height - size.height * reveal;
      path
        ..moveTo(0, y - 1)
        ..lineTo(size.width, y - 1)
        ..lineTo(size.width, y + 4)
        ..lineTo(0, y + 4)
        ..close();
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _PeelEdgeClipper oldClipper) =>
      oldClipper.progress != progress || oldClipper.isLandscape != isLandscape;
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FlipoutColors.surface1,
      borderRadius: BorderRadius.circular(FlipoutRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(FlipoutRadius.md),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FlipoutRadius.md),
            border: Border.all(color: FlipoutColors.border),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: FlipoutSpace.s3,
            vertical: FlipoutSpace.s2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: FlipoutColors.accentInk),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: FlipoutColors.accentInk,
                  fontSize: FlipoutType.xs,
                  fontWeight: FlipoutType.cta,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SqueezeButton extends StatefulWidget {
  const _SqueezeButton({
    required this.onPressStart,
    required this.onPressEnd,
    required this.progress,
  });

  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;
  final double progress;

  @override
  State<_SqueezeButton> createState() => _SqueezeButtonState();
}

class _SqueezeButtonState extends State<_SqueezeButton> {
  bool _pressed = false;

  void _handleDown() {
    setState(() => _pressed = true);
    widget.onPressStart();
  }

  void _handleUp() {
    if (!_pressed) return;
    setState(() => _pressed = false);
    widget.onPressEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _handleDown(),
      onPointerUp: (_) => _handleUp(),
      onPointerCancel: (_) => _handleUp(),
      child: AnimatedContainer(
        key: const Key('squeezeButton'),
        duration: const Duration(milliseconds: 120),
        height: 56,
        width: 168,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _pressed
                ? const [FlipoutColors.accentHover, FlipoutColors.accentInk]
                : const [FlipoutColors.accent, FlipoutColors.accentHover],
          ),
          borderRadius: BorderRadius.circular(FlipoutRadius.md),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40134e4a),
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compress, color: Colors.white, size: 22),
            SizedBox(width: FlipoutSpace.s2),
            Text(
              'SQUEEZE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FlipoutType.cta,
                fontSize: FlipoutType.md,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
