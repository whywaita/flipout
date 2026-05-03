import 'playing_card.dart';

class Player {
  const Player({
    required this.seatIndex,
    required this.name,
    this.holeCards = const [],
    this.equity,
    this.isWinner = false,
    this.highlightedCards = const {},
  });

  final int seatIndex;
  final String name;
  final List<PlayingCard> holeCards;
  final double? equity;
  final bool isWinner;
  final Set<PlayingCard> highlightedCards;

  Player copyWith({
    String? name,
    List<PlayingCard>? holeCards,
    double? equity,
    bool clearEquity = false,
    bool? isWinner,
    Set<PlayingCard>? highlightedCards,
  }) {
    return Player(
      seatIndex: seatIndex,
      name: name ?? this.name,
      holeCards: holeCards ?? this.holeCards,
      equity: clearEquity ? null : equity ?? this.equity,
      isWinner: isWinner ?? this.isWinner,
      highlightedCards: highlightedCards ?? this.highlightedCards,
    );
  }
}
