import 'package:flipout/models/game_phase.dart';
import 'package:flipout/models/playing_card.dart';
import 'package:flipout/services/equity_service.dart';
import 'package:flutter_test/flutter_test.dart';

List<PlayingCard> _cards(String codes) => [
  for (var i = 0; i < codes.length; i += 2)
    PlayingCard.parse(codes.substring(i, i + 2)),
];

void main() {
  const service = EquityService(preflopIterations: 20000);

  test('preflop AA is a big favourite over 72o', () async {
    final equity = await service.calculate(
      holeCards: [_cards('AsAh'), _cards('7c2d')],
      board: const [],
      phase: GamePhase.preflopDealt,
    );
    expect(equity[0], closeTo(0.87, 0.03));
    expect(equity[1], closeTo(0.13, 0.03));
  });

  test('preflop K2s is a favourite over T7o', () async {
    final equity = await service.calculate(
      holeCards: [_cards('7sTd'), _cards('2dKd')],
      board: const [],
      phase: GamePhase.preflopDealt,
    );
    expect(equity[1], greaterThan(equity[0]));
  });

  test('turn equity is exact for a made hand vs a drawing hand', () async {
    // Set over set on the turn: Ks Kh vs Qs Qh, board Kd Qd 2c 7h.
    // Only the last queen (Qc) saves player 2: 1 out of 44 cards.
    final equity = await service.calculate(
      holeCards: [_cards('KsKh'), _cards('QsQh')],
      board: _cards('KdQd2c7s'),
      phase: GamePhase.turnDealt,
    );
    expect(equity[1], closeTo(1 / 44, 1e-9));
    expect(equity[0], closeTo(43 / 44, 1e-9));
  });

  test('flop equity is exact over every turn and river', () async {
    // Quads on the flop: only a straight flush beats Ks Kh. 9s 8s with 7s
    // on board gets there with 6s5s, Ts6s or JsTs: 3 runouts.
    // Remaining deck: 52 - 4 hole - 3 board = 45 cards, C(45, 2) = 990.
    final equity = await service.calculate(
      holeCards: [_cards('KsKh'), _cards('9s8s')],
      board: _cards('KdKc7s'),
      phase: GamePhase.flopDealt,
    );
    expect(equity[1], closeTo(3 / 990, 1e-9));
  });

  test('split pots share equity evenly', () async {
    // Both players hold the same ranks with no flush potential, so every
    // river runout is a chop.
    final equity = await service.calculate(
      holeCards: [_cards('2c3d'), _cards('2d3c')],
      board: _cards('AhKsQhJs'),
      phase: GamePhase.turnDealt,
    );
    expect(equity[0], closeTo(equity[1], 1e-9));
    expect(equity[0] + equity[1], closeTo(1, 1e-9));
  });
}
