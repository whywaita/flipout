import 'package:flutter_test/flutter_test.dart';
import 'package:flipout/controllers/game_controller.dart';
import 'package:flipout/models/game_stage.dart';
import 'package:flipout/models/playing_card.dart';
import 'package:flipout/models/settings.dart';
import 'package:flipout/services/deck_service.dart';
import 'package:flipout/services/equity_service.dart';
import 'package:flipout/services/settings_store.dart';

class FakeEquityService implements EquityService {
  @override
  Future<List<double>> calculate({
    required List<List<PlayingCard>> holeCards,
    required List<PlayingCard> communityCards,
    required EquityMode mode,
    int? simulations,
  }) async {
    return List<double>.generate(
      holeCards.length,
      (index) => index == 0 ? 0.6 : 0.4 / (holeCards.length - 1),
    );
  }
}

void main() {
  test('strictly advances through the flip-out state machine', () async {
    final controller = GameController(
      deckService: DeckService.fixed(_orderedDeck()),
      equityService: FakeEquityService(),
      settingsStore: MemorySettingsStore(),
    );

    await controller.initialize();

    expect(controller.stage, GameStage.ready);
    expect(controller.players, hasLength(2));
    expect(controller.canDeal, isTrue);

    await controller.deal();
    expect(controller.stage, GameStage.preflopDealt);
    expect(
      controller.players.every((player) => player.holeCards.length == 2),
      isTrue,
    );
    expect(_allDealtCards(controller).toSet(), hasLength(4));
    expect(controller.players.map((player) => player.equity), [0.6, 0.4]);

    await controller.deal();
    expect(controller.stage, GameStage.flopDealt);
    expect(controller.board, hasLength(3));
    expect(controller.players.map((player) => player.equity), [0.6, 0.4]);

    await controller.deal();
    expect(controller.stage, GameStage.turnDealt);
    expect(controller.board, hasLength(4));
    expect(controller.players.map((player) => player.equity), [0.6, 0.4]);

    await controller.deal();
    expect(controller.stage, GameStage.riverSqueeze);
    expect(controller.board, hasLength(4));
    expect(controller.pendingRiver, isNotNull);
    expect(controller.canDeal, isFalse);
    expect(controller.players.every((player) => player.equity == null), isTrue);

    await controller.deal();
    expect(controller.stage, GameStage.riverSqueeze);

    controller.updateRiverSqueezeProgress(0.59);
    controller.releaseRiverSqueeze();
    expect(controller.stage, GameStage.riverSqueeze);
    expect(controller.riverSqueezeProgress, 0);

    controller.updateRiverSqueezeProgress(0.61);
    expect(controller.stage, GameStage.showdown);
    expect(controller.board, hasLength(5));
    expect(controller.pendingRiver, isNull);
    expect(controller.winningPlayerIndexes, isNotEmpty);
    expect(controller.players.every((player) => player.equity == null), isTrue);

    controller.newHand();
    expect(controller.stage, GameStage.ready);
    expect(controller.board, isEmpty);
    expect(
      controller.players.every((player) => player.holeCards.isEmpty),
      isTrue,
    );
  });

  test(
    'player count changes are only accepted during preflop and reset hand',
    () async {
      final controller = GameController(
        deckService: DeckService.fixed(_orderedDeck()),
        equityService: FakeEquityService(),
        settingsStore: MemorySettingsStore(),
      );

      await controller.initialize();
      controller.setPlayerCount(3);
      expect(controller.players, hasLength(2));

      await controller.deal();
      controller.setPlayerCount(4);

      expect(controller.stage, GameStage.ready);
      expect(controller.players, hasLength(4));
      expect(
        controller.players.every((player) => player.holeCards.isEmpty),
        isTrue,
      );

      controller.setPlayerCount(8);
      expect(controller.players, hasLength(4));
    },
  );

  test(
    'player names and color mode are persisted through the settings store',
    () async {
      final store = MemorySettingsStore(
        initial: const AppSettings(
          playerNames: ['Ada', 'Ben'],
          colorMode: CardColorMode.fourColor,
        ),
      );
      final controller = GameController(
        deckService: DeckService.fixed(_orderedDeck()),
        equityService: FakeEquityService(),
        settingsStore: store,
      );

      await controller.initialize();
      expect(controller.players.map((player) => player.name), ['Ada', 'Ben']);
      expect(controller.settings.colorMode, CardColorMode.fourColor);

      await controller.updatePlayerName(1, 'Charlie');
      await controller.updateColorMode(CardColorMode.twoColor);

      final persisted = await store.load();
      expect(persisted.playerNames.take(2), ['Ada', 'Charlie']);
      expect(persisted.colorMode, CardColorMode.twoColor);
    },
  );
}

List<PlayingCard> _allDealtCards(GameController controller) {
  return [
    for (final player in controller.players) ...player.holeCards,
    ...controller.board,
    if (controller.pendingRiver != null) controller.pendingRiver!,
  ];
}

List<PlayingCard> _orderedDeck() {
  return [
    PlayingCard.parse('As'),
    PlayingCard.parse('Ah'),
    PlayingCard.parse('Kc'),
    PlayingCard.parse('Kd'),
    PlayingCard.parse('Qs'),
    PlayingCard.parse('Jh'),
    PlayingCard.parse('Tc'),
    PlayingCard.parse('9d'),
    PlayingCard.parse('8s'),
    PlayingCard.parse('7h'),
    PlayingCard.parse('6c'),
    PlayingCard.parse('5d'),
    PlayingCard.parse('4s'),
    PlayingCard.parse('3h'),
    PlayingCard.parse('2c'),
  ];
}
