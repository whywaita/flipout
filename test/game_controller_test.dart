import 'package:flutter_test/flutter_test.dart';
import 'package:flipout/controllers/game_controller.dart';
import 'package:flipout/models/card_color_mode.dart';
import 'package:flipout/models/game_phase.dart';
import 'package:flipout/models/playing_card.dart';
import 'package:flipout/services/deck_service.dart';
import 'package:flipout/services/storage_service.dart';

import 'fake_equity_service.dart';

void main() {
  group('GameController state machine', () {
    test(
      'advances through the strict flow and never duplicates cards',
      () async {
        final controller = GameController(
          deckService: DeckService(randomSeed: 7),
          equityService: const FakeEquityService(),
          storageService: MemoryStorageService(),
        );

        await controller.deal();
        expect(controller.phase, GamePhase.preflopDealt);
        expect(controller.showPlayerCountControls, isTrue);
        expect(controller.showEquity, isTrue);
        expect(controller.players, hasLength(2));
        expect(
          controller.players.expand((player) => player.holeCards),
          hasLength(4),
        );

        await controller.deal();
        expect(controller.phase, GamePhase.flopDealt);
        expect(controller.board, hasLength(3));
        expect(controller.showPlayerCountControls, isFalse);
        expect(controller.showEquity, isTrue);

        await controller.deal();
        expect(controller.phase, GamePhase.turnDealt);
        expect(controller.board, hasLength(4));

        await controller.deal();
        expect(controller.phase, GamePhase.riverSqueeze);
        expect(controller.board, hasLength(4));
        expect(controller.hiddenRiverCard, isNotNull);
        expect(controller.showEquity, isFalse);

        await controller.deal();
        expect(controller.phase, GamePhase.riverSqueeze);

        await controller.completeRiverSqueeze(0.7);
        expect(controller.phase, GamePhase.showdown);
        expect(controller.board, hasLength(5));
        expect(
          controller.players.where((player) => player.isWinner),
          isNotEmpty,
        );

        final codes = [
          ...controller.board.map((card) => card.code),
          ...controller.players
              .expand((player) => player.holeCards)
              .map((card) => card.code),
        ];
        expect(codes.toSet(), hasLength(codes.length));

        controller.newHand();
        expect(controller.phase, GamePhase.ready);
        expect(controller.board, isEmpty);
        expect(
          controller.players.every((player) => player.holeCards.isEmpty),
          isTrue,
        );
      },
    );

    test(
      'allows player count changes only in preflop and resets to ready',
      () async {
        final controller = GameController(
          deckService: DeckService(randomSeed: 11),
          equityService: const FakeEquityService(),
          storageService: MemoryStorageService(),
        );

        controller.incrementPlayers();
        expect(controller.players, hasLength(2));

        await controller.deal();
        expect(controller.phase, GamePhase.preflopDealt);
        controller.incrementPlayers();
        expect(controller.phase, GamePhase.ready);
        expect(controller.players, hasLength(3));
        expect(
          controller.players.every((player) => player.holeCards.isEmpty),
          isTrue,
        );

        await controller.deal();
        await controller.deal();
        expect(controller.phase, GamePhase.flopDealt);
        controller.decrementPlayers();
        expect(controller.phase, GamePhase.flopDealt);
        expect(controller.players, hasLength(3));
      },
    );

    test('persists names and card color mode in settings storage', () async {
      final storage = MemoryStorageService();
      final controller = GameController(
        deckService: DeckService(randomSeed: 13),
        equityService: const FakeEquityService(),
        storageService: storage,
      );

      await controller.updatePlayerName(0, 'Alice');
      await controller.updateCardColorMode(CardColorMode.fourColor);

      final reloaded = GameController(
        deckService: DeckService(randomSeed: 13),
        equityService: const FakeEquityService(),
        storageService: storage,
      );
      await reloaded.loadSettings();

      expect(reloaded.players.first.name, 'Alice');
      expect(reloaded.cardColorMode, CardColorMode.fourColor);
    });

    test('highlights only the winner made hand at showdown', () async {
      final controller = GameController(
        deckService: DeckService.ordered([
          PlayingCard.parse('As'),
          PlayingCard.parse('Ks'),
          PlayingCard.parse('2c'),
          PlayingCard.parse('7d'),
          PlayingCard.parse('Qs'),
          PlayingCard.parse('Js'),
          PlayingCard.parse('Ts'),
          PlayingCard.parse('9h'),
          PlayingCard.parse('3c'),
        ]),
        equityService: const FakeEquityService(),
        storageService: MemoryStorageService(),
      );

      await controller.deal();
      await controller.deal();
      await controller.deal();
      await controller.deal();
      await controller.completeRiverSqueeze(0.9);

      expect(controller.players.first.isWinner, isTrue);
      expect(controller.players.last.isWinner, isFalse);
      expect(
        controller.players.first.winningCards.map((card) => card.code).toSet(),
        {'As', 'Ks', 'Qs', 'Js', 'Ts'},
      );
    });
  });
}
