export type Suit = 'h' | 'd' | 'c' | 's';
export type Rank = 'A' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' | 'T' | 'J' | 'Q' | 'K';
export type Card = `${Rank}${Suit}`;

const SUITS: Suit[] = ['h', 'd', 'c', 's'];
const RANKS: Rank[] = ['A', '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K'];

/**
 * Create a 52-card deck
 */
export function createDeck(): Card[] {
  return SUITS.flatMap(s => RANKS.map(r => `${r}${s}` as Card));
}

/**
 * Fisher-Yates shuffle (destructive)
 */
export function shuffleInPlace<T>(array: T[]): void {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
}

/**
 * Fisher-Yates shuffle (non-destructive)
 */
export function shuffle<T>(array: T[]): T[] {
  const result = [...array];
  shuffleInPlace(result);
  return result;
}

/**
 * Convert card to number 0-51 (for phe)
 * Ah=0, 2h=1, ..., Kh=12, Ad=13, ..., Ks=51
 */
export function cardToNumber(card: Card): number {
  const rank = card[0] as Rank;
  const suit = card[1] as Suit;
  const rankIndex = RANKS.indexOf(rank);
  const suitIndex = SUITS.indexOf(suit);
  return suitIndex * 13 + rankIndex;
}

/**
 * Convert number to card
 */
export function numberToCard(num: number): Card {
  const suitIndex = Math.floor(num / 13);
  const rankIndex = num % 13;
  return `${RANKS[rankIndex]}${SUITS[suitIndex]}` as Card;
}

/**
 * Convert multiple cards to number array
 */
export function cardsToNumbers(cards: Card[]): number[] {
  return cards.map(cardToNumber);
}

/**
 * Convert number array to cards
 */
export function numbersToCards(nums: number[]): Card[] {
  return nums.map(numberToCard);
}

/**
 * Exclude used cards from deck
 */
export function getRemainingDeck(usedCards: Card[]): Card[] {
  const deck = createDeck();
  const usedSet = new Set(usedCards);
  return deck.filter(c => !usedSet.has(c));
}

/**
 * Draw specified number of cards from deck (destructive)
 */
export function drawCards(deck: Card[], count: number): Card[] {
  return deck.splice(0, count);
}
