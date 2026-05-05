enum CardColorMode {
  twoColor,
  fourColor;

  String get label {
    switch (this) {
      case CardColorMode.twoColor:
        return '2-color';
      case CardColorMode.fourColor:
        return '4-color';
    }
  }

  static CardColorMode fromName(String? name) {
    return CardColorMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => CardColorMode.twoColor,
    );
  }
}
