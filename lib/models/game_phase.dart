enum GamePhase {
  ready,
  preflopDealt,
  flopDealt,
  turnDealt,
  riverSqueeze,
  showdown;

  String get label {
    switch (this) {
      case GamePhase.ready:
        return 'READY';
      case GamePhase.preflopDealt:
        return 'PREFLOP';
      case GamePhase.flopDealt:
        return 'FLOP';
      case GamePhase.turnDealt:
        return 'TURN';
      case GamePhase.riverSqueeze:
        return 'RIVER SQUEEZE';
      case GamePhase.showdown:
        return 'SHOWDOWN';
    }
  }
}
