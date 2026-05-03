enum GameStage {
  ready,
  preflopDealt,
  flopDealt,
  turnDealt,
  riverSqueeze,
  showdown,
}

extension GameStageLabel on GameStage {
  String get label {
    return switch (this) {
      GameStage.ready => 'Ready',
      GameStage.preflopDealt => 'Preflop',
      GameStage.flopDealt => 'Flop',
      GameStage.turnDealt => 'Turn',
      GameStage.riverSqueeze => 'River Squeeze',
      GameStage.showdown => 'Showdown',
    };
  }

  bool get showsEquity {
    return switch (this) {
      GameStage.preflopDealt ||
      GameStage.flopDealt ||
      GameStage.turnDealt => true,
      _ => false,
    };
  }
}
