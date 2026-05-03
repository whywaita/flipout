import 'package:flutter/foundation.dart';
import 'playing_card.dart';

@immutable
class Player {
  const Player({
    required this.id,
    required this.name,
    this.holeCards = const [],
    this.equity,
    this.isWinner = false,
    this.winningCards = const {},
  });

  final int id;
  final String name;
  final List<PlayingCard> holeCards;
  final double? equity;
  final bool isWinner;
  final Set<PlayingCard> winningCards;

  Player copyWith({
    String? name,
    List<PlayingCard>? holeCards,
    double? equity,
    bool clearEquity = false,
    bool? isWinner,
    Set<PlayingCard>? winningCards,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      holeCards: holeCards ?? this.holeCards,
      equity: clearEquity ? null : equity ?? this.equity,
      isWinner: isWinner ?? this.isWinner,
      winningCards: winningCards ?? this.winningCards,
    );
  }
}
