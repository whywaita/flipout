import { describe, it, expect } from 'vitest';
import { calculateEquity } from '../src/game/equity';
import type { Player } from '../src/game/player';
import type { Card } from '../src/game/deck';

describe('equity', () => {
  it('2人のプレイヤーでエクイティを計算できる', () => {
    const players: Player[] = [
      {
        id: 1,
        name: 'Player 1',
        holeCards: ['Ah', 'Kh'],
        isActive: true,
      },
      {
        id: 2,
        name: 'Player 2',
        holeCards: ['2c', '3c'],
        isActive: true,
      },
    ];

    const community: Card[] = [];
    const result = calculateEquity(players, community, 1000);

    expect(result.equities).toHaveLength(2);
    expect(result.samples).toBe(1000);

    // AKはポケット23より強いはず
    expect(result.equities[0]).toBeGreaterThan(result.equities[1]);

    // 合計は約1.0になるはず
    const sum = result.equities.reduce((a, b) => a + b, 0);
    expect(sum).toBeCloseTo(1.0, 1);
  });

  it('1人のプレイヤーの場合は100%を返す', () => {
    const players: Player[] = [
      {
        id: 1,
        name: 'Player 1',
        holeCards: ['Ah', 'Kh'],
        isActive: true,
      },
    ];

    const community: Card[] = [];
    const result = calculateEquity(players, community);

    expect(result.equities[0]).toBe(1.0);
    expect(result.samples).toBe(0);
  });
});
