import 'package:flutter/material.dart' hide Card;
import 'package:poker/poker.dart';
import '../models/settings.dart';
import 'playing_card.dart';

/// Widget for the River card squeeze animation
class RiverSqueeze extends StatefulWidget {
  final Card riverCard;
  final CardColorMode colorMode;
  final VoidCallback onSqueezeComplete;

  const RiverSqueeze({
    Key? key,
    required this.riverCard,
    required this.colorMode,
    required this.onSqueezeComplete,
  }) : super(key: key);

  @override
  State<RiverSqueeze> createState() => _RiverSqueezeState();
}

class _RiverSqueezeState extends State<RiverSqueeze> {
  double _revealProgress = 0.0;
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (_isCompleted) return;

        setState(() {
          // Update reveal progress based on drag
          _revealProgress += details.delta.dy / 300.0;
          _revealProgress = _revealProgress.clamp(0.0, 1.0);

          // Complete squeeze at 60% threshold
          if (_revealProgress >= 0.6 && !_isCompleted) {
            _isCompleted = true;
            _animateToComplete();
          }
        });
      },
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Fully revealed card (background)
              Positioned.fill(
                child: PlayingCard(
                  card: widget.riverCard,
                  colorMode: widget.colorMode,
                  width: 100,
                  height: 140,
                ),
              ),
              // Card back overlay with squeeze effect
              if (_revealProgress < 1.0)
                Positioned.fill(
                  child: ClipPath(
                    clipper: _SqueezeClipper(_revealProgress),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade900,
                            Colors.blue.shade700,
                          ],
                        ),
                      ),
                      child: CustomPaint(
                        painter: _CardBackPainter(),
                      ),
                    ),
                  ),
                ),
              // Corner reveal hint
              if (_revealProgress > 0.1 && _revealProgress < 0.6)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Opacity(
                    opacity: (_revealProgress - 0.1) / 0.5,
                    child: _buildCornerHint(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCornerHint() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _rankToString(widget.riverCard.rank),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _getSuitColor(widget.riverCard.suit),
        ),
      ),
    );
  }

  void _animateToComplete() {
    // Animate to fully revealed
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _revealProgress = 1.0;
        });
        // Notify completion
        Future.delayed(const Duration(milliseconds: 300), () {
          widget.onSqueezeComplete();
        });
      }
    });
  }

  Color _getSuitColor(Suit suit) {
    if (widget.colorMode == CardColorMode.fourColor) {
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
}

/// Custom clipper for squeeze effect
class _SqueezeClipper extends CustomClipper<Path> {
  final double progress;

  _SqueezeClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();

    if (progress <= 0.0) {
      // Fully covered
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    } else if (progress >= 1.0) {
      // Fully revealed (no clip)
      return path;
    } else {
      // Partial reveal from top-left corner
      final revealWidth = size.width * progress;
      final revealHeight = size.height * progress;

      path.moveTo(0, 0);
      path.lineTo(revealWidth, 0);
      path.lineTo(size.width, size.height - revealHeight);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
    }

    return path;
  }

  @override
  bool shouldReclip(_SqueezeClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

/// Painter for card back pattern
class _CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw diagonal pattern
    for (double i = -size.height; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
