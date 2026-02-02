import 'package:flutter_test/flutter_test.dart';
import 'package:flipout/controllers/game_controller.dart';
import 'package:flipout/models/game_state.dart';
import 'package:flipout/models/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GameController', () {
    late GameController controller;

    setUp(() async {
      // SharedPreferencesのモックを初期化
      SharedPreferences.setMockInitialValues({});
      controller = GameController();
      // 初期化完了を待つ
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('初期状態はReady', () {
      expect(controller.state, equals(GameState.ready));
    });

    test('DEAL押下でPreflop状態に遷移', () async {
      await controller.onDeal();
      expect(controller.state, equals(GameState.preflopDealt));
      expect(controller.players.every((p) => p.holeCards.length == 2), isTrue);
    });

    test('状態遷移フロー: Ready -> Preflop -> Flop -> Turn -> River -> Showdown',
        () async {
      // Ready -> Preflop
      await controller.onDeal();
      expect(controller.state, equals(GameState.preflopDealt));

      // Preflop -> Flop
      await controller.onDeal();
      expect(controller.state, equals(GameState.flopDealt));
      expect(controller.communityCards.length, equals(3));

      // Flop -> Turn
      await controller.onDeal();
      expect(controller.state, equals(GameState.turnDealt));
      expect(controller.communityCards.length, equals(4));

      // Turn -> River Squeeze
      await controller.onDeal();
      expect(controller.state, equals(GameState.riverSqueeze));

      // River Squeeze -> Showdown
      await controller.completeRiverSqueeze();
      expect(controller.state, equals(GameState.showdown));
      expect(controller.communityCards.length, equals(5));
      expect(controller.players.any((p) => p.isWinner), isTrue);
    });

    test('newHand()で状態がリセットされる', () async {
      // ゲームを進める
      await controller.onDeal();
      await controller.onDeal();

      // リセット
      controller.newHand();

      expect(controller.state, equals(GameState.ready));
      expect(controller.communityCards.isEmpty, isTrue);
      expect(controller.players.every((p) => p.holeCards.isEmpty), isTrue);
    });

    test('プレイヤー数を変更できる', () async {
      expect(controller.settings.playerCount, equals(2));

      // Preflopまで進める
      await controller.onDeal();
      expect(controller.state, equals(GameState.preflopDealt));

      controller.changePlayerCount(6);

      expect(controller.settings.playerCount, equals(6));
      expect(controller.players.length, equals(6));
    });

    test('設定を更新できる', () async {
      final newSettings = Settings(
        playerCount: 2, // 現在のプレイヤー数を維持
        playerNames: ['Alice', 'Bob'],
        cardColorMode: CardColorMode.twoColor,
      );

      await controller.updateSettings(newSettings);

      expect(controller.settings.playerCount, equals(2));
      expect(controller.settings.cardColorMode, equals(CardColorMode.twoColor));
      expect(controller.players.length, equals(2));
      expect(controller.players[0].name, equals('Alice'));
      expect(controller.players[1].name, equals('Bob'));
    });
  });
}
