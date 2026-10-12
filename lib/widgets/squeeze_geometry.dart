import 'dart:math' as math;
import 'dart:ui';

/// The card edge being lifted during a river squeeze. Like a baccarat
/// squeeze, the card is bent from a side or from the top, so the fold line
/// always runs parallel to that edge.
enum SqueezeEdge { left, top, right, bottom }

SqueezeEdge nearestEdge(Size size, Offset point) {
  final distances = {
    SqueezeEdge.left: point.dx,
    SqueezeEdge.top: point.dy,
    SqueezeEdge.right: size.width - point.dx,
    SqueezeEdge.bottom: size.height - point.dy,
  };
  return distances.entries.reduce((a, b) => b.value < a.value ? b : a).key;
}

/// Geometry of a card whose [edge] has been dragged by [delta].
///
/// Only the part of the drag that crosses the card counts, so the fold line
/// stays parallel to the lifted edge. Everything between the edge and the
/// fold is lifted (the face shows through); the rest is still covered.
class SqueezeFold {
  factory SqueezeFold(Size size, SqueezeEdge edge, Offset delta) {
    final normal = _inward(edge);
    final across = delta.dx * normal.dx + delta.dy * normal.dy;
    final distance = across.clamp(0.0, _extent(size, edge));
    return SqueezeFold._(size, edge, normal, distance);
  }

  /// The fold that reveals [fraction] of the card when bending [edge].
  factory SqueezeFold.forFraction(
    Size size,
    SqueezeEdge edge,
    double fraction,
  ) {
    final distance = fraction.clamp(0.0, 1.0) * _extent(size, edge);
    return SqueezeFold._(size, edge, _inward(edge), distance);
  }

  SqueezeFold._(this.size, this.edge, this.normal, this.distance);

  final Size size;
  final SqueezeEdge edge;

  /// Unit vector from the lifted edge into the card.
  final Offset normal;

  /// How far the fold line sits from the lifted edge along [normal].
  final double distance;

  /// A point on the lifted edge.
  Offset get origin => switch (edge) {
    SqueezeEdge.left || SqueezeEdge.top => Offset.zero,
    SqueezeEdge.right || SqueezeEdge.bottom => Offset(size.width, size.height),
  };

  /// Distance of [point] from the lifted edge, measured along [normal].
  double depthOf(Offset point) {
    final v = point - origin;
    return v.dx * normal.dx + v.dy * normal.dy;
  }

  List<Offset> get _card => [
    Offset.zero,
    Offset(size.width, 0),
    Offset(size.width, size.height),
    Offset(0, size.height),
  ];

  /// Part of the card already lifted, so the face shows here.
  List<Offset> get revealedPolygon {
    if (distance <= 0) return const [];
    return _clip(_card, (p) => distance - depthOf(p));
  }

  /// Part of the card still lying face down.
  List<Offset> get coveredPolygon {
    return _clip(_card, (p) => depthOf(p) - distance);
  }

  double get revealedFraction {
    final total = size.width * size.height;
    if (total == 0) return 0;
    return (polygonArea(revealedPolygon) / total).clamp(0.0, 1.0);
  }

  /// Width of the rolled-up band of card stock next to the fold.
  double get curlWidth => math.min(distance * 0.5, size.shortestSide * 0.16);

  /// The rolled-up band of card stock: the strip of lifted card nearest the
  /// fold, mirrored over the fold onto the covered side.
  List<Offset> get curlPolygon {
    if (distance <= 0) return const [];
    final strip = _clip(
      revealedPolygon,
      (p) => depthOf(p) - (distance - curlWidth),
    );
    final mirrored = [
      for (final p in strip) p + normal * (2 * (distance - depthOf(p))),
    ];
    var clipped = mirrored;
    clipped = _clip(clipped, (p) => p.dx);
    clipped = _clip(clipped, (p) => size.width - p.dx);
    clipped = _clip(clipped, (p) => p.dy);
    clipped = _clip(clipped, (p) => size.height - p.dy);
    return clipped;
  }

  /// The two points where the fold line meets the card edge.
  List<Offset> get foldEdge {
    final covered = coveredPolygon;
    return [
      for (final p in covered)
        if ((depthOf(p) - distance).abs() < 1e-6) p,
    ];
  }

  static Offset _inward(SqueezeEdge edge) => switch (edge) {
    SqueezeEdge.left => const Offset(1, 0),
    SqueezeEdge.top => const Offset(0, 1),
    SqueezeEdge.right => const Offset(-1, 0),
    SqueezeEdge.bottom => const Offset(0, -1),
  };

  static double _extent(Size size, SqueezeEdge edge) => switch (edge) {
    SqueezeEdge.left || SqueezeEdge.right => size.width,
    SqueezeEdge.top || SqueezeEdge.bottom => size.height,
  };

  /// Sutherland–Hodgman clip keeping points where [inside] is >= 0.
  static List<Offset> _clip(
    List<Offset> polygon,
    double Function(Offset) inside,
  ) {
    if (polygon.isEmpty) return const [];
    final result = <Offset>[];
    for (var i = 0; i < polygon.length; i += 1) {
      final a = polygon[i];
      final b = polygon[(i + 1) % polygon.length];
      final fa = inside(a);
      final fb = inside(b);
      if (fa >= 0) result.add(a);
      if ((fa >= 0) != (fb >= 0)) {
        final t = fa / (fa - fb);
        result.add(Offset.lerp(a, b, t)!);
      }
    }
    // A sliver left when the fold sits exactly on an edge has no area.
    return polygonArea(result) < 1e-9 ? const [] : result;
  }
}

/// Unsigned shoelace area.
double polygonArea(List<Offset> polygon) {
  var sum = 0.0;
  for (var i = 0; i < polygon.length; i += 1) {
    final a = polygon[i];
    final b = polygon[(i + 1) % polygon.length];
    sum += a.dx * b.dy - b.dx * a.dy;
  }
  return sum.abs() / 2;
}
