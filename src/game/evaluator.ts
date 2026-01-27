import { evaluateCards } from 'phe';
import type { Card } from './deck';

/**
 * Evaluate hand strength from 7 cards
 * @param cards Card string array (7 cards)
 * @returns Hand strength (lower value is stronger, phe specification)
 */
export function evaluate7Cards(cards: Card[]): number {
  if (cards.length !== 7) {
    throw new Error('Evaluation requires exactly 7 cards');
  }
  return evaluateCards(cards);
}

/**
 * Evaluate multiple hands and return strongest rank
 * @param handsCards Each player's 7-card array
 * @returns Each player's hand strength
 */
export function evaluateHands(handsCards: Card[][]): number[] {
  return handsCards.map(cards => evaluate7Cards(cards));
}

/**
 * Get winner indices from hand strength
 * @param ranks Hand strength array (lower value is stronger)
 * @returns Winner index array (supports ties)
 */
export function getWinners(ranks: number[]): number[] {
  const minRank = Math.min(...ranks);
  return ranks
    .map((rank, index) => (rank === minRank ? index : -1))
    .filter(index => index !== -1);
}
