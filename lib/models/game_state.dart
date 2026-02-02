/// Game state machine states
enum GameState {
  /// S0: No cards dealt
  ready,

  /// S1: Hole cards dealt, Preflop equity shown
  preflopDealt,

  /// S2: Flop revealed, Flop equity shown
  flopDealt,

  /// S3: Turn revealed, Turn equity shown
  turnDealt,

  /// S4: River card hidden, squeeze in progress
  riverSqueeze,

  /// S5: River revealed, hand results displayed
  showdown,
}
