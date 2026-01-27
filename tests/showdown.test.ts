import { describe, it, expect } from 'vitest';
import { determineWinners } from '../src/game/showdown';
import type { Player } from '../src/game/player';
import type { Card } from '../src/game/deck';

describe('showdown', () => {
  it('強いハンドを持つプレイヤーが勝つ', () => {
    const players: Player[] = [
      {
        id: 1,
        name: 'Player 1',
        holeCards: ['Ah', 'Kh'], // フラッシュ
        isActive: true,
      },
      {
        id: 2,
        name: 'Player 2',
        holeCards: ['2c', '3c'], // ハイカード
        isActive: true,
      },
    ];

    const community: Card[] = ['Qh', 'Jh', 'Th', '5d', '7s'];
    const result = determineWinners(players, community);

    expect(result.winners).toHaveLength(1);
    expect(result.winners[0]).toBe(1);
  });

  it('引き分けの場合は複数の勝者を返す', () => {
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
        holeCards: ['Ad', 'Kd'],
        isActive: true,
      },
    ];

    const community: Card[] = ['Qc', 'Jc', 'Tc', '5s', '7h'];
    const result = determineWinners(players, community);

    // 両方ともストレート（A-high）なので引き分け
    expect(result.winners).toHaveLength(2);
    expect(result.winners).toContain(1);
    expect(result.winners).toContain(2);
  });
});
