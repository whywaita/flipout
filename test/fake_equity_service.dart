import 'package:flipout/models/game_phase.dart';
import 'package:flipout/models/playing_card.dart';
import 'package:flipout/services/equity_service.dart';

class FakeEquityService implements EquityCalculator {
  const FakeEquityService();

  @override
  Future<List<double>> calculate({
    required List<List<PlayingCard>> holeCards,
    required List<PlayingCard> board,
    required GamePhase phase,
  }) async {
    return List.filled(holeCards.length, 1 / holeCards.length);
  }
}
