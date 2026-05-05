import 'card_color_mode.dart';

class AppSettings {
  const AppSettings({
    required this.playerCount,
    required this.playerNames,
    required this.cardColorMode,
  });

  factory AppSettings.defaults() {
    return AppSettings(
      playerCount: 2,
      playerNames: List.generate(8, (index) => 'Player ${index + 1}'),
      cardColorMode: CardColorMode.twoColor,
    );
  }

  final int playerCount;
  final List<String> playerNames;
  final CardColorMode cardColorMode;

  AppSettings copyWith({
    int? playerCount,
    List<String>? playerNames,
    CardColorMode? cardColorMode,
  }) {
    return AppSettings(
      playerCount: playerCount ?? this.playerCount,
      playerNames: playerNames ?? this.playerNames,
      cardColorMode: cardColorMode ?? this.cardColorMode,
    );
  }

  String nameFor(int index) {
    if (index < playerNames.length && playerNames[index].trim().isNotEmpty) {
      return playerNames[index].trim();
    }

    return 'Player ${index + 1}';
  }
}
