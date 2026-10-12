import 'dart:ui';

import 'package:flipout/widgets/squeeze_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const card = Size(100, 140);

  test('picks the edge nearest to the touch point', () {
    expect(nearestEdge(card, const Offset(4, 70)), SqueezeEdge.left);
    expect(nearestEdge(card, const Offset(95, 50)), SqueezeEdge.right);
    expect(nearestEdge(card, const Offset(50, 6)), SqueezeEdge.top);
    expect(nearestEdge(card, const Offset(40, 133)), SqueezeEdge.bottom);
  });

  test('nothing is revealed before the edge moves', () {
    final fold = SqueezeFold(card, SqueezeEdge.right, Offset.zero);
    expect(fold.revealedFraction, 0);
    expect(fold.revealedPolygon, isEmpty);
  });

  test('dragging away from the card reveals nothing', () {
    final fold = SqueezeFold(card, SqueezeEdge.right, const Offset(40, 0));
    expect(fold.revealedFraction, 0);
  });

  test('a side squeeze lifts a strip parallel to the long edge', () {
    final fold = SqueezeFold(card, SqueezeEdge.left, const Offset(20, 0));
    expect(fold.revealedFraction, closeTo(0.2, 1e-9));
    for (final point in fold.revealedPolygon) {
      expect(point.dx, lessThanOrEqualTo(20 + 1e-9));
    }
  });

  test('a top squeeze lifts a strip parallel to the short edge', () {
    final fold = SqueezeFold(card, SqueezeEdge.top, const Offset(0, 28));
    expect(fold.revealedFraction, closeTo(0.2, 1e-9));
    for (final point in fold.revealedPolygon) {
      expect(point.dy, lessThanOrEqualTo(28 + 1e-9));
    }
  });

  test('only the drag across the edge counts, so the fold stays straight', () {
    final fold = SqueezeFold(card, SqueezeEdge.bottom, const Offset(35, -14));
    expect(fold.normal, const Offset(0, -1));
    expect(fold.revealedFraction, closeTo(0.1, 1e-9));
  });

  test('dragging across the whole card reveals everything', () {
    final fold = SqueezeFold(card, SqueezeEdge.right, const Offset(-100, 0));
    expect(fold.revealedFraction, closeTo(1, 1e-9));
    expect(fold.coveredPolygon, isEmpty);
  });

  test('revealed and covered parts always tile the card', () {
    for (final edge in SqueezeEdge.values) {
      final fold = SqueezeFold.forFraction(card, edge, 0.37);
      expect(
        polygonArea(fold.revealedPolygon) + polygonArea(fold.coveredPolygon),
        closeTo(card.width * card.height, 1e-6),
      );
    }
  });

  test('the curl lies on the covered side of the fold', () {
    final fold = SqueezeFold(card, SqueezeEdge.top, const Offset(0, 40));
    expect(fold.curlPolygon, isNotEmpty);
    for (final point in fold.curlPolygon) {
      expect(fold.depthOf(point), greaterThanOrEqualTo(fold.distance - 1e-9));
    }
  });

  test('forFraction inverts revealedFraction for every edge', () {
    for (final edge in SqueezeEdge.values) {
      for (final target in const [0.05, 0.3, 0.6, 0.95]) {
        final fold = SqueezeFold.forFraction(card, edge, target);
        expect(fold.revealedFraction, closeTo(target, 1e-9));
      }
    }
  });
}
