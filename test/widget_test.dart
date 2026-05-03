import 'package:flutter_test/flutter_test.dart';
import 'package:flipout/app.dart';
import 'package:flipout/controllers/game_controller.dart';
import 'package:flipout/models/playing_card.dart';
import 'package:flipout/services/deck_service.dart';
import 'package:flipout/services/settings_store.dart';
import 'package:flipout/widgets/river_squeeze_card.dart';

import 'game_controller_test.dart';

void main() {
  testWidgets('renders the usable flip-out screen as the first view', (
    tester,
  ) async {
    final controller = GameController(
      deckService: DeckService.fixed([
        PlayingCard.parse('As'),
        PlayingCard.parse('Ah'),
        PlayingCard.parse('Kc'),
        PlayingCard.parse('Kd'),
        PlayingCard.parse('Qs'),
        PlayingCard.parse('Jh'),
        PlayingCard.parse('Tc'),
        PlayingCard.parse('9d'),
        PlayingCard.parse('8s'),
      ]),
      equityService: FakeEquityService(),
      settingsStore: MemorySettingsStore(),
    );
    await controller.initialize();

    await tester.pumpWidget(FlipoutApp(controller: controller));

    expect(find.text('Flip-Out'), findsOneWidget);
    expect(find.text('DEAL'), findsOneWidget);
    expect(find.text('Player 1'), findsOneWidget);
    expect(find.text('Player 2'), findsOneWidget);

    await tester.tap(find.text('DEAL'));
    await tester.pumpAndSettle();

    expect(find.text('Preflop'), findsOneWidget);
    expect(find.text('60.0%'), findsOneWidget);
    expect(find.text('40.0%'), findsOneWidget);
  });

  testWidgets('walks through deal, river squeeze, showdown, and new hand', (
    tester,
  ) async {
    final controller = GameController(
      deckService: DeckService.fixed([
        PlayingCard.parse('Ah'),
        PlayingCard.parse('Ad'),
        PlayingCard.parse('Kc'),
        PlayingCard.parse('Kd'),
        PlayingCard.parse('As'),
        PlayingCard.parse('7d'),
        PlayingCard.parse('7c'),
        PlayingCard.parse('2h'),
        PlayingCard.parse('3s'),
      ]),
      equityService: FakeEquityService(),
      settingsStore: MemorySettingsStore(),
    );
    await controller.initialize();
    await tester.pumpWidget(FlipoutApp(controller: controller));

    await tester.tap(find.text('DEAL'));
    await tester.pumpAndSettle();
    expect(find.text('Preflop'), findsOneWidget);

    await tester.tap(find.text('DEAL'));
    await tester.pumpAndSettle();
    expect(find.text('Flop'), findsOneWidget);

    await tester.tap(find.text('DEAL'));
    await tester.pumpAndSettle();
    expect(find.text('Turn'), findsOneWidget);

    await tester.tap(find.text('DEAL'));
    await tester.pumpAndSettle();
    expect(find.text('River Squeeze'), findsOneWidget);
    expect(find.text('SQUEEZE'), findsOneWidget);
    expect(find.text('60.0%'), findsNothing);

    await tester.drag(find.byType(RiverSqueezeCard), const Offset(-160, 160));
    await tester.pumpAndSettle();
    expect(find.text('Showdown'), findsOneWidget);
    expect(find.text('NEW HAND'), findsOneWidget);

    await tester.tap(find.text('NEW HAND'));
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('DEAL'), findsOneWidget);
  });
}
