import type { Card } from './deck';
import type { Player } from './player';
import { evaluate7Cards, getWinners } from './evaluator';

export interface ShowdownResult {
  winners: number[];
  ranks: number[];
}

/**
 * Determine winner at showdown
 * @param players Player array
 * @param community Community cards (5 cards)
 * @returns Winner player ID array and hand strength
 */
export function determineWinners(
  players: Player[],
  community: Card[]
): ShowdownResult {
  if (community.length !== 5) {
    throw new Error('Showdown requires 5 community cards');
  }

  const activePlayers = players.filter(p => p.isActive && p.holeCards.length === 2);

  if (activePlayers.length === 0) {
    throw new Error('No active players exist');
  }

  // Evaluate each player's hand strength
  const ranks = activePlayers.map(p => {
    const sevenCards: Card[] = [...(p.holeCards as [Card, Card]), ...community];
    return evaluate7Cards(sevenCards);
  });

  // Determine winner
  const winnerIndices = getWinners(ranks);
  const winnerIds = winnerIndices.map(i => activePlayers[i].id);

  return { winners: winnerIds, ranks };
}

/**
 * Convert hand strength to rank name
 * phe only returns numbers, so perform rough rank classification
 */
export function rankToHandName(rank: number): string {
  // phe return value is 1-7462 (1 is strongest Royal Flush)
  // Rough classification (actual boundary values need adjustment)
  if (rank <= 10) return 'Royal Flush';
  if (rank <= 166) return 'Straight Flush';
  if (rank <= 322) return 'Four of a Kind';
  if (rank <= 1599) return 'Full House';
  if (rank <= 1599 + 1277) return 'Flush';
  if (rank <= 1599 + 1277 + 10) return 'Straight';
  if (rank <= 1599 + 1277 + 10 + 858) return 'Three of a Kind';
  if (rank <= 1599 + 1277 + 10 + 858 + 858) return 'Two Pair';
  if (rank <= 1599 + 1277 + 10 + 858 + 858 + 2860) return 'One Pair';
  return 'High Card';
}
