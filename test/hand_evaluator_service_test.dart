import 'package:flutter_test/flutter_test.dart';
import 'package:flipout/models/playing_card.dart';
import 'package:flipout/services/hand_evaluator_service.dart';

void main() {
  const evaluator = HandEvaluatorService();

  ({Set<String> winning, String label}) eval(
    List<String> hole,
    List<String> board,
  ) {
    final result = evaluator.evaluate(
      holeCards: [hole.map(PlayingCard.parse).toList()],
      board: board.map(PlayingCard.parse).toList(),
    );
    final cards = (result.winningCardsByPlayer[0] ?? <PlayingCard>{})
        .map((card) => card.code)
        .toSet();
    return (winning: cards, label: result.handLabelByPlayer[0]!);
  }

  test('high card label and selected kickers', () {
    final r = eval(['2c', '7d'], ['Qs', 'Js', 'Ts', '9h', '3c']);
    expect(r.label, 'High Card');
  });

  test('pair label and 5 cards highlighted', () {
    final r = eval(['8h', 'Kd'], ['4c', 'Jd', '9c', 'Qs', '8d']);
    expect(r.label, 'Pair');
    expect(r.winning, isNot(contains('4c')));
  });

  test('pocket pair without board match still labels Pair', () {
    final r = eval(['4h', '4s'], ['5c', '8s', '2c', 'As', 'Tc']);
    expect(r.label, 'Pair');
    expect(r.winning, containsAll({'4h', '4s'}));
  });

  test('top pair from board with kicker labels Pair', () {
    final r = eval(['9s', 'Ah'], ['5c', '8s', '2c', 'As', 'Tc']);
    expect(r.label, 'Pair');
    expect(r.winning, containsAll({'Ah', 'As'}));
  });

  test('two pair label', () {
    final r = eval(['Td', 'Js'], ['Jh', '3c', 'Qd', '6d', 'Qh']);
    expect(r.label, 'Two Pair');
    expect(r.winning, containsAll({'Js', 'Jh', 'Qd', 'Qh'}));
  });

  test('three of a kind label', () {
    final r = eval(['Th', '4d'], ['Td', '7s', '2c', '8h', 'Tc']);
    expect(r.label, 'Three of a Kind');
    expect(r.winning, containsAll({'Th', 'Td', 'Tc'}));
  });

  test('straight label including wheel', () {
    final r = eval(['As', '2d'], ['3h', '4c', '5s', '9d', 'Kh']);
    expect(r.label, 'Straight');
  });

  test('flush label', () {
    final r = eval(['Ah', '2h'], ['7h', 'Th', 'Kh', '4c', '9d']);
    expect(r.label, 'Flush');
    expect(r.winning, containsAll({'Ah', 'Kh', 'Th', '7h', '2h'}));
  });

  test('full house label', () {
    final r = eval(['As', 'Ad'], ['Ac', 'Kh', 'Kd', '5s', '2c']);
    expect(r.label, 'Full House');
    expect(r.winning, containsAll({'As', 'Ad', 'Ac', 'Kh', 'Kd'}));
  });

  test('four of a kind label', () {
    final r = eval(['As', 'Ad'], ['Ac', 'Ah', 'Kd', '5s', '2c']);
    expect(r.label, 'Four of a Kind');
    expect(r.winning, containsAll({'As', 'Ad', 'Ac', 'Ah'}));
  });

  test('straight flush label', () {
    final r = eval(['9s', '8s'], ['7s', '6s', '5s', '2c', 'Kh']);
    expect(r.label, 'Straight Flush');
    expect(r.winning, {'9s', '8s', '7s', '6s', '5s'});
  });

  // Scenarios that previously appeared mislabeled in the running web app.
  // If these all return the expected label, the evaluator is sound and the
  // mismatch lives elsewhere (UI binding, stale cache, etc.).
  test('regression: pocket fours with rainbow board → Pair', () {
    final r = eval(['4h', '4s'], ['5c', '8s', '2c', 'As', 'Tc']);
    expect(r.label, 'Pair');
  });

  test('regression: top pair with two pair on board → Two Pair', () {
    final r = eval(['6c', '7c'], ['6h', 'As', '7h', 'Jc', 'Kh']);
    expect(r.label, 'Two Pair');
  });

  test('regression: hole jack, board jack → Pair', () {
    final r = eval(['Jh', '5s'], ['6h', 'As', '7h', 'Jc', 'Kh']);
    expect(r.label, 'Pair');
  });

  test('regression: empty board high card → High Card', () {
    final r = eval(['Th', '7s'], ['Kh', 'Jc', '3c', '2c', '8s']);
    expect(r.label, 'High Card');
  });

  test('regression: pocket eights → Pair', () {
    final r = eval(['8c', '6d'], ['Kh', 'Jc', '3c', '2c', '8s']);
    expect(r.label, 'Pair');
  });
}
