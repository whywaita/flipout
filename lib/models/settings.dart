/// Card color mode
enum CardColorMode {
  twoColor,
  fourColor,
}

/// Application settings
class Settings {
  int playerCount;
  List<String> playerNames;
  CardColorMode cardColorMode;

  Settings({
    this.playerCount = 2,
    List<String>? playerNames,
    this.cardColorMode = CardColorMode.fourColor,
  }) : playerNames = playerNames ?? _defaultPlayerNames(playerCount);

  static List<String> _defaultPlayerNames(int count) {
    return List.generate(count, (i) => 'Player ${i + 1}');
  }

  Settings copyWith({
    int? playerCount,
    List<String>? playerNames,
    CardColorMode? cardColorMode,
  }) {
    return Settings(
      playerCount: playerCount ?? this.playerCount,
      playerNames: playerNames ?? this.playerNames,
      cardColorMode: cardColorMode ?? this.cardColorMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerCount': playerCount,
      'playerNames': playerNames,
      'cardColorMode': cardColorMode.index,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      playerCount: json['playerCount'] as int,
      playerNames: (json['playerNames'] as List<dynamic>).cast<String>(),
      cardColorMode: CardColorMode.values[json['cardColorMode'] as int],
    );
  }
}
