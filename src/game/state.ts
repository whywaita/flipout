/**
 * Represents the game state
 */
export enum GameState {
  Ready = 0,        // S0: Before game starts or right after NEW HAND
  PreflopDealt,     // S1: Preflop cards dealt
  FlopDealt,        // S2: Flop dealt
  TurnDealt,        // S3: Turn dealt
  RiverSqueeze,     // S4: River card face down (waiting for squeeze)
  Showdown,         // S5: Showdown (winner determined)
}

/**
 * Convert state to string
 */
export function stateToString(state: GameState): string {
  switch (state) {
    case GameState.Ready:
      return 'Ready';
    case GameState.PreflopDealt:
      return 'PreflopDealt';
    case GameState.FlopDealt:
      return 'FlopDealt';
    case GameState.TurnDealt:
      return 'TurnDealt';
    case GameState.RiverSqueeze:
      return 'RiverSqueeze';
    case GameState.Showdown:
      return 'Showdown';
    default:
      return 'Unknown';
  }
}

/**
 * Check if DEAL button is enabled for current state
 */
export function canDeal(state: GameState): boolean {
  return state >= GameState.Ready && state < GameState.RiverSqueeze;
}

/**
 * Check if NEW HAND button is enabled for current state
 * Only enabled in Showdown state
 */
export function canNewHand(state: GameState): boolean {
  return state === GameState.Showdown;
}

/**
 * Check if player count can be changed in current state
 */
export function canChangePlayerCount(state: GameState): boolean {
  return state === GameState.Ready || state === GameState.PreflopDealt;
}

/**
 * Return next state after DEAL button is pressed
 */
export function nextState(state: GameState): GameState {
  switch (state) {
    case GameState.Ready:
      return GameState.PreflopDealt;
    case GameState.PreflopDealt:
      return GameState.FlopDealt;
    case GameState.FlopDealt:
      return GameState.TurnDealt;
    case GameState.TurnDealt:
      return GameState.RiverSqueeze;
    case GameState.RiverSqueeze:
      // Transition to Showdown after squeeze animation completes
      return GameState.RiverSqueeze;
    default:
      return state;
  }
}

/**
 * Check if equity should be displayed in current state
 */
export function showsEquity(state: GameState): boolean {
  // Show equity in Preflop/Flop/Turn, hide after River
  return state >= GameState.PreflopDealt && state <= GameState.TurnDealt;
}
