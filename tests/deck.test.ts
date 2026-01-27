import { describe, it, expect } from 'vitest';
import {
  createDeck,
  shuffle,
  cardToNumber,
  numberToCard,
  getRemainingDeck,
  type Card
} from '../src/game/deck';

describe('deck', () => {
  it('createDeck は52枚のカードを生成する', () => {
    const deck = createDeck();
    expect(deck).toHaveLength(52);
  });

  it('shuffle はカードをシャッフルする', () => {
    const deck = createDeck();
    const shuffled = shuffle(deck);
    expect(shuffled).toHaveLength(52);
    // 元のデッキと異なることを確認（稀に同じになる可能性あり）
    expect(shuffled).not.toEqual(deck);
  });

  it('cardToNumber と numberToCard は相互変換できる', () => {
    const card: Card = 'Ah';
    const num = cardToNumber(card);
    expect(num).toBe(0);
    expect(numberToCard(num)).toBe(card);
  });

  it('getRemainingDeck は使用済みカードを除外する', () => {
    const used: Card[] = ['Ah', '2h', '3h'];
    const remaining = getRemainingDeck(used);
    expect(remaining).toHaveLength(49);
    expect(remaining).not.toContain('Ah');
    expect(remaining).not.toContain('2h');
    expect(remaining).not.toContain('3h');
  });
});
