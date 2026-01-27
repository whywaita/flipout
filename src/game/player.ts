import type { Card } from './deck';

export interface Player {
  id: number;
  name: string;
  holeCards: [Card, Card] | [];
  isActive: boolean;
  equity?: number;
}

/**
 * Create players
 */
export function createPlayers(count: number): Player[] {
  if (count < 2 || count > 8) {
    throw new Error('Player count must be between 2 and 8');
  }

  return Array.from({ length: count }, (_, i) => ({
    id: i + 1,
    name: `Player ${i + 1}`,
    holeCards: [],
    isActive: true,
  }));
}

/**
 * Deal hole cards to players
 */
export function dealHoleCards(players: Player[], cards: Card[][]): void {
  if (cards.length !== players.length) {
    throw new Error('Card count and player count do not match');
  }

  players.forEach((player, i) => {
    if (cards[i].length !== 2) {
      throw new Error('Each player needs 2 hole cards');
    }
    player.holeCards = [cards[i][0], cards[i][1]];
  });
}

/**
 * Get only active players
 */
export function getActivePlayers(players: Player[]): Player[] {
  return players.filter(p => p.isActive);
}

/**
 * Update player equities
 */
export function updateEquities(players: Player[], equities: number[]): void {
  if (equities.length !== players.length) {
    throw new Error('Equity count and player count do not match');
  }

  players.forEach((player, i) => {
    player.equity = equities[i];
  });
}

/**
 * Clear all player equities
 */
export function clearEquities(players: Player[]): void {
  players.forEach(p => {
    p.equity = undefined;
  });
}
