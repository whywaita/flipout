const minPlayers = 2;
const maxPlayers = 8;

enum CardColorMode { twoColor, fourColor }

class AppSettings {
  const AppSettings({required this.playerNames, required this.colorMode});

  factory AppSettings.defaults() {
    return AppSettings(
      playerNames: List.generate(maxPlayers, defaultPlayerName),
      colorMode: CardColorMode.twoColor,
    );
  }

  final List<String> playerNames;
  final CardColorMode colorMode;

  String playerNameAt(int index) {
    if (index < playerNames.length && playerNames[index].trim().isNotEmpty) {
      return playerNames[index];
    }
    return defaultPlayerName(index);
  }

  AppSettings copyWith({List<String>? playerNames, CardColorMode? colorMode}) {
    return AppSettings(
      playerNames: playerNames ?? this.playerNames,
      colorMode: colorMode ?? this.colorMode,
    );
  }
}

String defaultPlayerName(int index) => 'Player ${index + 1}';
