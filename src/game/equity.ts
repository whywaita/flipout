import type { Card } from './deck';
import type { Player } from './player';
import { getRemainingDeck, shuffleInPlace } from './deck';
import { evaluate7Cards } from './evaluator';

const DEFAULT_SAMPLES = 10_000;

export interface EquityResult {
  equities: number[];
  samples: number;
}

/**
 * Calculate equity using Monte Carlo simulation
 * @param players Player array
 * @param community Community cards
 * @param samples Number of simulations (default: 10,000)
 * @returns Equity for each player (0-1 range)
 */
export function calculateEquity(
  players: Player[],
  community: Card[],
  samples: number = DEFAULT_SAMPLES
): EquityResult {
  // Target only active players
  const activePlayers = players.filter(p => p.isActive && p.holeCards.length === 2);

  if (activePlayers.length === 0) {
    throw new Error('No active players exist');
  }

  if (activePlayers.length === 1) {
    // 100% if only one player
    return {
      equities: players.map(p => (p.isActive && p.holeCards.length === 2 ? 1.0 : 0.0)),
      samples: 0
    };
  }

  // Collect used cards
  const usedCards: Card[] = [
    ...community,
    ...activePlayers.flatMap(p => p.holeCards),
  ];

  // Get remaining deck
  const remainingDeck = getRemainingDeck(usedCards);
  const cardsNeeded = 5 - community.length;

  // Win and tie counters
  const wins = new Array(activePlayers.length).fill(0);
  const ties = new Array(activePlayers.length).fill(0);

  // Monte Carlo simulation
  for (let i = 0; i < samples; i++) {
    // Shuffle deck and deal remaining cards
    shuffleInPlace(remainingDeck);
    const simulatedCommunity = [...community, ...remainingDeck.slice(0, cardsNeeded)];

    // Evaluate each player's hand strength
    const ranks = activePlayers.map(p => {
      const sevenCards: Card[] = [...(p.holeCards as [Card, Card]), ...simulatedCommunity];
      return evaluate7Cards(sevenCards);
    });

    // Determine winner (phe: lower value is stronger)
    const minRank = Math.min(...ranks);
    const winnerCount = ranks.filter(r => r === minRank).length;

    ranks.forEach((rank, idx) => {
      if (rank === minRank) {
        if (winnerCount === 1) {
          wins[idx]++;
        } else {
          ties[idx] += 1 / winnerCount;
        }
      }
    });
  }

  // Calculate equity
  const activeEquities = activePlayers.map((_, i) => (wins[i] + ties[i]) / samples);

  // Convert to all players' equity
  let activeIndex = 0;
  const equities = players.map(p => {
    if (p.isActive && p.holeCards.length === 2) {
      return activeEquities[activeIndex++];
    }
    return 0.0;
  });

  return { equities, samples };
}

/**
 * Convert equity to percentage string
 */
export function formatEquity(equity: number): string {
  return `${(equity * 100).toFixed(1)}%`;
}
