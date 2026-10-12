import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_color_mode.dart';
import '../models/playing_card.dart';
import '../theme/tokens.dart';
import 'playing_card_view.dart';
import 'squeeze_geometry.dart';

/// Baccarat-style river reveal: the player bends the face-down card up a
/// little at a time from a side or the top and reads the rank from the pips
/// underneath. The face carries no corner index.
///
/// Releasing below [threshold] lays the card back down; releasing above it,
/// or peeling the whole card, reports completion through [onRelease].
class RiverSqueezeCard extends StatefulWidget {
  const RiverSqueezeCard({
    super.key,
    required this.card,
    required this.progress,
    required this.onProgress,
    required this.onRelease,
    this.threshold = 0.6,
  });

  final PlayingCard card;

  /// Progress to restore when the card is rebuilt mid-squeeze.
  final double progress;
  final ValueChanged<double> onProgress;
  final ValueChanged<double> onRelease;
  final double threshold;

  @override
  State<RiverSqueezeCard> createState() => _RiverSqueezeCardState();
}

class _RiverSqueezeCardState extends State<RiverSqueezeCard>
    with SingleTickerProviderStateMixin {
  static const _settleDuration = Duration(milliseconds: 260);
  static const _completeAt = 0.99;
  static const _a11yStep = 0.2;

  late final AnimationController _settle;
  final FocusNode _focusNode = FocusNode(debugLabel: 'riverSqueeze');

  Size _cardSize = Size.zero;
  SqueezeEdge _edge = SqueezeEdge.right;
  Offset _delta = Offset.zero;
  Offset _dragStart = Offset.zero;
  Offset _settleFrom = Offset.zero;
  double? _restoreFraction;
  double _fraction = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _restoreFraction = widget.progress > 0 ? widget.progress : null;
    _settle = AnimationController(vsync: this, duration: _settleDuration)
      ..addListener(_handleSettleTick);
  }

  @override
  void dispose() {
    _settle.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  SqueezeFold get _fold => SqueezeFold(_cardSize, _edge, _delta);

  void _handlePanStart(DragStartDetails details) {
    if (_completed) return;
    _settle.stop();
    _edge = nearestEdge(_cardSize, details.localPosition);
    _dragStart = details.localPosition;
    _setDelta(Offset.zero);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_completed) return;
    _setDelta(details.localPosition - _dragStart);
  }

  void _handlePanEnd() {
    if (_completed || !mounted) return;
    if (_fraction >= widget.threshold) {
      _complete();
      return;
    }
    _settleFrom = _delta;
    _settle.value = 1;
    _settle.reverse();
  }

  void _handleSettleTick() {
    if (_completed) return;
    _setDelta(_settleFrom * _settle.value);
  }

  /// Bends the card from the side by [fraction].
  void _setFraction(double fraction) {
    if (_completed || _cardSize.isEmpty) return;
    _settle.stop();
    _edge = SqueezeEdge.right;
    final fold = SqueezeFold.forFraction(_cardSize, _edge, fraction);
    _setDelta(fold.normal * fold.distance);
    if (fraction >= widget.threshold && fraction < _completeAt) {
      // Without a finger to lift, a keyboard or screen-reader step past the
      // threshold is the release.
      _complete();
    }
  }

  void _setDelta(Offset delta) {
    final previous = _fraction;
    setState(() => _delta = delta);
    _fraction = _fold.revealedFraction;
    _haptics(previous, _fraction);
    widget.onProgress(_fraction);
    if (_fraction >= _completeAt) {
      _complete();
    }
  }

  void _haptics(double previous, double next) {
    if (next <= previous) return;
    if (previous < widget.threshold && next >= widget.threshold) {
      HapticFeedback.mediumImpact();
    } else if ((next * 5).floor() > (previous * 5).floor()) {
      HapticFeedback.selectionClick();
    }
  }

  void _complete() {
    if (_completed) return;
    _completed = true;
    _settle.stop();
    widget.onRelease(1);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowRight) {
      _setFraction(math.min(1, _fraction + _a11yStep));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft) {
      _setFraction(math.max(0, _fraction - _a11yStep));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _complete();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  static String _percent(double fraction) => '${(fraction * 100).round()}%';

  static const _hintGap = FlipoutSpace.s2;
  static const _hintHeight = 24.0;

  static Size _fitCard(BoxConstraints constraints) {
    const aspect = 5 / 7;
    // Leave room for the hint plus the card's hard edge and drop shadow.
    var height = math.min(
      constraints.maxHeight - _hintGap - _hintHeight - 16,
      380.0,
    );
    var width = height * aspect;
    final maxWidth = constraints.maxWidth * 0.78;
    if (width > maxWidth) {
      width = maxWidth;
      height = width / aspect;
    }
    return Size(math.max(width, 0), math.max(height, 0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCard(constraints),
            const SizedBox(height: _hintGap),
            SizedBox(
              height: _hintHeight,
              child: Center(
                child: ExcludeSemantics(
                  child: Text(
                    _fraction > 0
                        ? _percent(_fraction)
                        : 'Drag an edge to squeeze',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FlipoutColors.textMuted,
                      fontWeight: FlipoutType.cta,
                      fontSize: FlipoutType.sm,
                      letterSpacing: 1.2,
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

  Widget _buildCard(BoxConstraints constraints) {
    _cardSize = _fitCard(constraints);
    final restore = _restoreFraction;
    if (restore != null && !_cardSize.isEmpty) {
      _restoreFraction = null;
      final fold = SqueezeFold.forFraction(_cardSize, _edge, restore);
      _delta = fold.normal * fold.distance;
      _fraction = fold.revealedFraction;
    }

    return Center(
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKey,
        // A button, not a slider: Flutter web renders slider semantics as an
        // <input type=range> without an accessible name.
        child: Semantics(
          container: true,
          button: true,
          label: 'Reveal river card',
          onTap: _complete,
          child: GestureDetector(
            key: const Key('squeezeCard'),
            dragStartBehavior: DragStartBehavior.down,
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: (_) => _handlePanEnd(),
            onPanCancel: _handlePanEnd,
            child: SizedBox.fromSize(
              size: _cardSize,
              child: _PeeledCard(
                card: widget.card,
                size: _cardSize,
                fold: _fold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeeledCard extends StatelessWidget {
  const _PeeledCard({
    required this.card,
    required this.size,
    required this.fold,
  });

  final PlayingCard card;
  final Size size;
  final SqueezeFold fold;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size.width * 0.06);
    return DecoratedBox(
      // Thick card stock: a hard edge just below the card plus a soft drop.
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(color: Color(0xff0b6b62), offset: Offset(0, 3)),
          BoxShadow(
            color: Color(0x330f172a),
            offset: Offset(0, 14),
            blurRadius: 28,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The face sits under the back until the squeeze reveals it, so
            // it must not leak the card to screen readers. Squeeze is always
            // two-colour so the suit stays hidden until its shape shows.
            ExcludeSemantics(
              child: PlayingCardView(
                card: card,
                colorMode: CardColorMode.twoColor,
                face: CardFace.pips,
                size: size,
              ),
            ),
            ClipPath(
              clipper: _PolygonClipper(fold.coveredPolygon),
              child: ExcludeSemantics(
                child: PlayingCardView(
                  card: null,
                  colorMode: CardColorMode.twoColor,
                  faceDown: true,
                  size: size,
                ),
              ),
            ),
            CustomPaint(painter: _CurlPainter(fold)),
          ],
        ),
      ),
    );
  }
}

class _PolygonClipper extends CustomClipper<Path> {
  const _PolygonClipper(this.polygon);

  final List<Offset> polygon;

  @override
  Path getClip(Size size) => Path()..addPolygon(polygon, true);

  @override
  bool shouldReclip(covariant _PolygonClipper oldClipper) =>
      !_samePolygon(oldClipper.polygon, polygon);
}

/// Paints the lifted edge: the shadow it casts on the revealed face and
/// the rolled-up band of card stock lying over the back.
class _CurlPainter extends CustomPainter {
  const _CurlPainter(this.fold);

  final SqueezeFold fold;

  @override
  void paint(Canvas canvas, Size size) {
    if (fold.distance <= 0) return;
    final origin = fold.origin;
    final n = fold.normal;
    final d = fold.distance;
    final curl = fold.curlWidth;
    final shade = math.min(d, size.shortestSide * 0.12);

    Offset at(double depth) => origin + n * depth;

    // Shadow under the lifted card, falling on the face near the fold.
    canvas.save();
    canvas.clipPath(Path()..addPolygon(fold.revealedPolygon, true));
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = _gradientBetween(at(d - shade), at(d), const [
          Color(0x00000000),
          Color(0x40000000),
        ]),
    );
    canvas.restore();

    // Contact shadow the curl casts on the back beyond it.
    final beyond = Path()..addPolygon(fold.coveredPolygon, true);
    canvas.save();
    canvas.clipPath(beyond);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = _gradientBetween(at(d + curl), at(d + curl + 10), const [
          Color(0x40000000),
          Color(0x00000000),
        ]),
    );
    canvas.restore();

    // The rolled card stock itself: light along the crease, shaded where it
    // turns away, with a crisp outer edge.
    final band = fold.curlPolygon;
    if (band.isEmpty) return;
    final bandPath = Path()..addPolygon(band, true);
    canvas.drawPath(
      bandPath,
      Paint()
        ..shader = _gradientBetween(at(d), at(d + curl), const [
          Color(0xffd6dde5),
          Color(0xfffdfefe),
          Color(0xffe8edf2),
        ]),
    );
    canvas.drawPath(
      bandPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x260f172a),
    );
  }

  /// A gradient whose stops run from [from] to [to], clamped beyond them.
  static Shader _gradientBetween(Offset from, Offset to, List<Color> colors) {
    final stops = [
      for (var i = 0; i < colors.length; i += 1) i / (colors.length - 1),
    ];
    return ui.Gradient.linear(from, to, colors, stops);
  }

  @override
  bool shouldRepaint(covariant _CurlPainter oldDelegate) =>
      oldDelegate.fold.distance != fold.distance ||
      oldDelegate.fold.normal != fold.normal ||
      oldDelegate.fold.edge != fold.edge ||
      oldDelegate.fold.size != fold.size;
}

bool _samePolygon(List<Offset> a, List<Offset> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
