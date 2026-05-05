import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flipout/app.dart';
import 'package:flipout/controllers/game_controller.dart';
import 'package:flipout/models/game_phase.dart';
import 'package:flipout/models/playing_card.dart';
import 'package:flipout/services/deck_service.dart';
import 'package:flipout/services/storage_service.dart';

import 'fake_equity_service.dart';

void main() {
  testWidgets('player count controls are visible only in the ready phase', (
    tester,
  ) async {
    final controller = GameController(
      deckService: DeckService(randomSeed: 23),
      equityService: const FakeEquityService(),
      storageService: MemoryStorageService(),
    );

    await tester.pumpWidget(FlipoutApp(controller: controller));

    expect(controller.phase, GamePhase.ready);
    expect(find.byKey(const Key('incrementPlayers')), findsOneWidget);
    expect(find.byKey(const Key('decrementPlayers')), findsOneWidget);

    await tester.tap(find.byKey(const Key('dealButton')));
    await tester.pumpAndSettle();

    expect(controller.phase, GamePhase.preflopDealt);
    expect(find.byKey(const Key('incrementPlayers')), findsNothing);
    expect(find.byKey(const Key('decrementPlayers')), findsNothing);
  });

  testWidgets('walks through deal, squeeze, showdown, and new hand', (
    tester,
  ) async {
    final controller = GameController(
      deckService: DeckService(randomSeed: 29),
      equityService: const FakeEquityService(),
      storageService: MemoryStorageService(),
    );

    await tester.pumpWidget(FlipoutApp(controller: controller));

    await tester.tap(find.byKey(const Key('dealButton')));
    await tester.pumpAndSettle();
    expect(controller.phase, GamePhase.preflopDealt);

    await tester.tap(find.byKey(const Key('dealButton')));
    await tester.pumpAndSettle();
    expect(controller.phase, GamePhase.flopDealt);

    await tester.tap(find.byKey(const Key('dealButton')));
    await tester.pumpAndSettle();
    expect(controller.phase, GamePhase.turnDealt);

    await tester.tap(find.byKey(const Key('dealButton')));
    await tester.pumpAndSettle();
    expect(controller.phase, GamePhase.riverSqueeze);
    expect(find.byKey(const Key('riverSqueeze')), findsOneWidget);
    expect(find.byKey(const Key('squeezeButton')), findsOneWidget);
    expect(find.byKey(const Key('rotateButton')), findsOneWidget);

    await controller.completeRiverSqueeze(1);
    await tester.pumpAndSettle();

    expect(controller.phase, GamePhase.showdown);
    expect(find.text('SHOWDOWN'), findsOneWidget);

    await tester.tap(find.byKey(const Key('newHandButton')));
    await tester.pumpAndSettle();
    expect(controller.phase, GamePhase.ready);
  });

  testWidgets('hand label appears in showdown row matching evaluated label', (
    tester,
  ) async {
    final controller = GameController(
      deckService: DeckService.ordered([
        PlayingCard.parse('Th'),
        PlayingCard.parse('7s'),
        PlayingCard.parse('8c'),
        PlayingCard.parse('6d'),
        PlayingCard.parse('Kh'),
        PlayingCard.parse('Jc'),
        PlayingCard.parse('3c'),
        PlayingCard.parse('2c'),
        PlayingCard.parse('8s'),
      ]),
      equityService: const FakeEquityService(),
      storageService: MemoryStorageService(),
    );

    await tester.pumpWidget(FlipoutApp(controller: controller));

    await tester.tap(find.byKey(const Key('dealButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dealButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dealButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dealButton')));
    await tester.pumpAndSettle();
    await controller.completeRiverSqueeze(0.9);
    await tester.pumpAndSettle();

    expect(controller.phase, GamePhase.showdown);
    expect(controller.players.first.handLabel, 'High Card');
    expect(controller.players.last.handLabel, 'Pair');

    expect(find.text('High Card'), findsOneWidget);
    expect(find.text('Pair'), findsOneWidget);
  });
}
