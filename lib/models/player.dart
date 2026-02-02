import 'package:poker/poker.dart';

/// Represents a player in the game
class Player {
  final int index;
  String name;
  List<Card> holeCards;
  double? equity;
  bool isWinner;
  List<Card>? winningHand; // The 5 cards that make up the winning hand

  Player({
    required this.index,
    required this.name,
    this.holeCards = const [],
    this.equity,
    this.isWinner = false,
    this.winningHand,
  });

  Player copyWith({
    int? index,
    String? name,
    List<Card>? holeCards,
    double? equity,
    bool? isWinner,
    List<Card>? winningHand,
  }) {
    return Player(
      index: index ?? this.index,
      name: name ?? this.name,
      holeCards: holeCards ?? this.holeCards,
      equity: equity ?? this.equity,
      isWinner: isWinner ?? this.isWinner,
      winningHand: winningHand ?? this.winningHand,
    );
  }
}
