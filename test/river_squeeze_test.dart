import 'package:flipout/app.dart';
import 'package:flipout/controllers/game_controller.dart';
import 'package:flipout/models/card_color_mode.dart';
import 'package:flipout/models/game_phase.dart';
import 'package:flipout/models/playing_card.dart';
import 'package:flipout/services/deck_service.dart';
import 'package:flipout/services/storage_service.dart';
import 'package:flipout/widgets/playing_card_view.dart';
import 'package:flipout/widgets/squeeze_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_equity_service.dart';

const _squeezeCard = Key('squeezeCard');

GameController _controller() {
  // Deal order: P1, P2, flop, turn, river (9c).
  return GameController(
    deckService: DeckService.ordered(
      [
        'Ah',
        'Kh',
        'Qd',
        'Jd',
        '2h',
        '3d',
        '4s',
        '5s',
        '9c',
      ].map(PlayingCard.parse).toList(),
    ),
    equityService: const FakeEquityService(),
    storageService: MemoryStorageService(),
  );
}

Future<GameController> _pumpToSqueeze(WidgetTester tester) async {
  final controller = _controller();
  await tester.pumpWidget(FlipoutApp(controller: controller));
  for (var i = 0; i < 4; i += 1) {
    await tester.tap(find.byKey(const Key('dealButton')));
    await tester.pumpAndSettle();
  }
  expect(controller.phase, GamePhase.riverSqueeze);
  return controller;
}

/// Starts a drag just inside the middle of [edge] on the squeeze card and
/// moves it straight across by the drag that reveals [fraction].
Future<TestGesture> _peel(
  WidgetTester tester,
  SqueezeEdge edge,
  double fraction,
) async {
  final rect = tester.getRect(find.byKey(_squeezeCard));
  final fold = SqueezeFold.forFraction(rect.size, edge, fraction);
  final start =
      rect.center - _halfSpan(rect.size, fold.normal) + fold.normal * 4;
  final gesture = await tester.startGesture(start);
  const steps = 12;
  final delta = fold.normal * fold.distance;
  for (var i = 0; i < steps; i += 1) {
    await gesture.moveBy(delta / steps.toDouble());
    await tester.pump(const Duration(milliseconds: 16));
  }
  return gesture;
}

Offset _halfSpan(Size size, Offset normal) =>
    Offset(normal.dx * size.width / 2, normal.dy * size.height / 2);

void main() {
  testWidgets('squeeze has no buttons and is not inside a scroll view', (
    tester,
  ) async {
    await _pumpToSqueeze(tester);
    final stage = find.byKey(const Key('riverSqueeze'));
    expect(
      find.descendant(of: stage, matching: find.byType(InkWell)),
      findsNothing,
    );
    expect(
      find.ancestor(of: stage, matching: find.byType(Scrollable)),
      findsNothing,
    );
  });

  testWidgets('releasing a small peel lays the card back down', (tester) async {
    final controller = await _pumpToSqueeze(tester);
    final gesture = await _peel(tester, SqueezeEdge.right, 0.3);
    expect(controller.squeezeProgress, closeTo(0.3, 0.05));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.phase, GamePhase.riverSqueeze);
    expect(controller.squeezeProgress, 0);
  });

  testWidgets('the card can be squeezed again after laying it back down', (
    tester,
  ) async {
    final controller = await _pumpToSqueeze(tester);
    var gesture = await _peel(tester, SqueezeEdge.right, 0.2);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.squeezeProgress, 0);

    gesture = await _peel(tester, SqueezeEdge.top, 0.3);
    expect(controller.squeezeProgress, closeTo(0.3, 0.05));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('releasing past the threshold reveals the river', (tester) async {
    final controller = await _pumpToSqueeze(tester);
    final gesture = await _peel(tester, SqueezeEdge.right, 0.7);
    expect(controller.phase, GamePhase.riverSqueeze);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.phase, GamePhase.showdown);
    expect(controller.board.last, PlayingCard.parse('9c'));
  });

  testWidgets('peeling all the way completes while the finger is down', (
    tester,
  ) async {
    final controller = await _pumpToSqueeze(tester);
    final gesture = await _peel(tester, SqueezeEdge.right, 1);
    await tester.pumpAndSettle();
    expect(controller.phase, GamePhase.showdown);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('any edge can be squeezed', (tester) async {
    final controller = await _pumpToSqueeze(tester);
    final gesture = await _peel(tester, SqueezeEdge.top, 0.4);
    expect(controller.squeezeProgress, closeTo(0.4, 0.05));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a slanted drag from the side still folds straight', (
    tester,
  ) async {
    final controller = await _pumpToSqueeze(tester);
    final rect = tester.getRect(find.byKey(_squeezeCard));
    final gesture = await tester.startGesture(
      rect.centerLeft + const Offset(6, 0),
    );
    for (var i = 0; i < 10; i += 1) {
      await gesture.moveBy(Offset(rect.width * 0.03, rect.height * 0.02));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(controller.squeezeProgress, closeTo(0.3, 0.03));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('dragging away from the card does not reveal it', (tester) async {
    final controller = await _pumpToSqueeze(tester);
    final rect = tester.getRect(find.byKey(_squeezeCard));
    final gesture = await tester.startGesture(
      rect.bottomRight - const Offset(4, 4),
    );
    for (var i = 0; i < 8; i += 1) {
      await gesture.moveBy(const Offset(6, 8));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(controller.squeezeProgress, 0);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('the squeezed face shows pips in two colours but no index', (
    tester,
  ) async {
    final controller = _controller();
    await controller.updateCardColorMode(CardColorMode.fourColor);
    await tester.pumpWidget(FlipoutApp(controller: controller));
    for (var i = 0; i < 4; i += 1) {
      await tester.tap(find.byKey(const Key('dealButton')));
      await tester.pumpAndSettle();
    }

    final stage = find.byKey(const Key('riverSqueeze'));
    final faces = tester
        .widgetList<PlayingCardView>(
          find.descendant(of: stage, matching: find.byType(PlayingCardView)),
        )
        .where((view) => !view.faceDown && view.card != null);
    expect(faces, isNotEmpty);
    expect(
      faces.every((view) => view.colorMode == CardColorMode.twoColor),
      isTrue,
    );
    // Like a baccarat squeeze, only the pips tell the rank: no corner index.
    expect(find.descendant(of: stage, matching: find.text('9')), findsNothing);
    expect(
      find.descendant(of: stage, matching: find.text('♣')),
      findsNWidgets(9),
    );
  });

  testWidgets('crossing the threshold triggers haptic feedback', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await _pumpToSqueeze(tester);
    final gesture = await _peel(tester, SqueezeEdge.right, 0.7);
    expect(
      calls.where((call) => call.method == 'HapticFeedback.vibrate'),
      isNotEmpty,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('assistive technology reveals the river with a button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final controller = await _pumpToSqueeze(tester);

    // A labelled button rather than a slider: Flutter web renders slider
    // semantics as an <input type=range> that carries no accessible name.
    final node = tester.getSemantics(find.byKey(_squeezeCard));
    expect(
      node,
      isSemantics(
        label: 'Reveal river card',
        isButton: true,
        hasTapAction: true,
        hasIncreaseAction: false,
      ),
    );

    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(controller.phase, GamePhase.showdown);
    handle.dispose();
  });

  testWidgets('keyboard arrows squeeze and Enter reveals', (tester) async {
    final controller = await _pumpToSqueeze(tester);
    final focus = tester.widget<Focus>(
      find
          .ancestor(of: find.byKey(_squeezeCard), matching: find.byType(Focus))
          .first,
    );
    focus.focusNode!.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(controller.squeezeProgress, closeTo(0.2, 0.02));
    expect(controller.phase, GamePhase.riverSqueeze);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(controller.phase, GamePhase.showdown);
  });

  testWidgets('the hint sits right under the card', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpToSqueeze(tester);
    final card = tester.getRect(find.byKey(_squeezeCard));
    final hint = tester.getRect(find.text('Drag an edge to squeeze'));
    expect(hint.top - card.bottom, inInclusiveRange(0, 24));
  });

  testWidgets('court cards fill a large face', (tester) async {
    const size = Size(180, 252);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: PlayingCardView(
            card: PlayingCard.parse('Kd'),
            colorMode: CardColorMode.twoColor,
            face: CardFace.pips,
            size: size,
          ),
        ),
      ),
    );
    final tallest = tester
        .widgetList<Text>(find.text('K'))
        .map((text) => tester.getRect(find.byWidget(text)).height)
        .reduce((a, b) => a > b ? a : b);
    expect(tallest, greaterThan(size.height * 0.2));
  });

  testWidgets('a side squeeze reaches the outer pip column early', (
    tester,
  ) async {
    const size = Size(180, 252);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: PlayingCardView(
            card: PlayingCard.parse('9c'),
            colorMode: CardColorMode.twoColor,
            face: CardFace.pips,
            size: size,
          ),
        ),
      ),
    );
    final card = tester.getRect(find.byType(PlayingCardView));
    final rightmost = tester
        .widgetList<Text>(find.text('♣'))
        .map((text) => tester.getRect(find.byWidget(text)).right)
        .reduce((a, b) => a > b ? a : b);
    // Bending a fifth of the card from the side uncovers part of a pip.
    expect(card.right - rightmost, lessThan(size.width * 0.2));
  });

  testWidgets('squeeze fits a small phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpToSqueeze(tester);
    expect(tester.takeException(), isNull);
    final card = tester.getRect(find.byKey(_squeezeCard));
    expect(card.height, greaterThan(150));
    expect(card.bottom, lessThanOrEqualTo(568));
  });
}
