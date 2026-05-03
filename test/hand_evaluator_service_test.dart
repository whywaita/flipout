import 'package:flutter_test/flutter_test.dart';
import 'package:flipout/models/playing_card.dart';
import 'package:flipout/services/hand_evaluator_service.dart';

void main() {
  test('selects the winner and the exact five cards used by that hand', () {
    final result = const HandEvaluatorService().evaluate(
      holeCards: [
        [PlayingCard.parse('Ah'), PlayingCard.parse('Ad')],
        [PlayingCard.parse('Kc'), PlayingCard.parse('Kd')],
      ],
      board: [
        PlayingCard.parse('As'),
        PlayingCard.parse('7d'),
        PlayingCard.parse('7c'),
        PlayingCard.parse('2h'),
        PlayingCard.parse('3s'),
      ],
    );

    expect(result.winningPlayerIndexes, {0});
    expect(result.players[0].bestFiveCards, {
      PlayingCard.parse('Ah'),
      PlayingCard.parse('Ad'),
      PlayingCard.parse('As'),
      PlayingCard.parse('7d'),
      PlayingCard.parse('7c'),
    });
    expect(result.boardHighlights, {
      PlayingCard.parse('As'),
      PlayingCard.parse('7d'),
      PlayingCard.parse('7c'),
    });
  });

  test('keeps per-player highlight sets for tied hands', () {
    final result = const HandEvaluatorService().evaluate(
      holeCards: [
        [PlayingCard.parse('Ah'), PlayingCard.parse('2d')],
        [PlayingCard.parse('Ac'), PlayingCard.parse('3d')],
      ],
      board: [
        PlayingCard.parse('Ks'),
        PlayingCard.parse('Qh'),
        PlayingCard.parse('Jd'),
        PlayingCard.parse('Tc'),
        PlayingCard.parse('2s'),
      ],
    );

    expect(result.winningPlayerIndexes, {0, 1});
    expect(result.players[0].bestFiveCards, {
      PlayingCard.parse('Ah'),
      PlayingCard.parse('Ks'),
      PlayingCard.parse('Qh'),
      PlayingCard.parse('Jd'),
      PlayingCard.parse('Tc'),
    });
    expect(result.players[1].bestFiveCards, {
      PlayingCard.parse('Ac'),
      PlayingCard.parse('Ks'),
      PlayingCard.parse('Qh'),
      PlayingCard.parse('Jd'),
      PlayingCard.parse('Tc'),
    });
  });
}
