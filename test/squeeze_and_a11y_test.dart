import 'package:flipout/app.dart';
import 'package:flipout/controllers/game_controller.dart';
import 'package:flipout/models/card_color_mode.dart';
import 'package:flipout/models/playing_card.dart';
import 'package:flipout/services/deck_service.dart';
import 'package:flipout/services/storage_service.dart';
import 'package:flipout/theme/tokens.dart';
import 'package:flipout/widgets/playing_card_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_equity_service.dart';

GameController _controller() {
  // Deal order: P1, P2, flop, turn, river. The river is the only club.
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

Future<void> _dealToSqueeze(WidgetTester tester) async {
  for (var i = 0; i < 4; i += 1) {
    await tester.tap(find.byKey(const Key('dealButton')));
    await tester.pumpAndSettle();
  }
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  testWidgets('player count steppers have accessible names', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(FlipoutApp(controller: _controller()));

    expect(find.bySemanticsLabel('Add player'), findsOneWidget);
    expect(find.bySemanticsLabel('Remove player'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('hidden river card is not exposed to assistive technology', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final controller = _controller();
    await tester.pumpWidget(FlipoutApp(controller: controller));
    await _dealToSqueeze(tester);
    expect(controller.hiddenRiverCard, PlayingCard.parse('9c'));

    expect(find.bySemanticsLabel(RegExp('♣')), findsNothing);
    handle.dispose();
  });

  testWidgets('deal button announces itself as disabled during squeeze', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(FlipoutApp(controller: _controller()));

    expect(
      tester.getSemantics(find.byKey(const Key('dealButton'))),
      isSemantics(
        label: 'DEAL',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );

    await _dealToSqueeze(tester);
    expect(
      tester.getSemantics(find.byKey(const Key('dealButton'))),
      isSemantics(
        label: 'DEAL',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  test('dim text meets WCAG AA contrast on surfaces', () {
    expect(
      _contrast(FlipoutColors.textDim, FlipoutColors.surface1),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('board cards show one rank character and one suit mark', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    for (final rank in CardRank.values) {
      final card = PlayingCard(rank: rank, suit: CardSuit.club);
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: PlayingCardView(
              card: card,
              colorMode: CardColorMode.twoColor,
            ),
          ),
        ),
      );

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .toList();
      expect(texts, [rank.code, '♣'], reason: card.code);
      expect(rank.code, hasLength(1));
      expect(
        find.bySemanticsLabel('${rank.name} of clubs'),
        findsOneWidget,
        reason: card.code,
      );
    }
    handle.dispose();
  });

  testWidgets('board rank and suit are large and do not overlap', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: PlayingCardView(
            card: PlayingCard.parse('Td'),
            colorMode: CardColorMode.twoColor,
          ),
        ),
      ),
    );
    final card = tester.getRect(find.byType(PlayingCardView));
    final rank = tester.getRect(find.text('T'));
    final suit = tester.getRect(find.text('♦'));
    expect(rank.height, greaterThan(card.height * 0.35));
    expect(suit.height, greaterThan(card.height * 0.25));
    final overlap = rank.intersect(suit);
    expect(overlap.width > 0.5 && overlap.height > 0.5, isFalse);
    expect(card.contains(rank.center) && card.contains(suit.center), isTrue);
  });

  testWidgets('hole cards use the same rank-and-suit design as the board', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: PlayingCardView(
            card: PlayingCard.parse('Qh'),
            colorMode: CardColorMode.twoColor,
            compact: true,
          ),
        ),
      ),
    );
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .toList();
    expect(texts, ['Q', '♥']);

    final card = tester.getRect(find.byType(PlayingCardView));
    final rank = tester.getRect(find.text('Q'));
    final suit = tester.getRect(find.text('♥'));
    expect(rank.height, greaterThan(card.height * 0.35));
    expect(suit.height, greaterThan(card.height * 0.25));
    final overlap = rank.intersect(suit);
    expect(overlap.width > 0.5 && overlap.height > 0.5, isFalse);
  });
}
