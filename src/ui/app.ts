import type { Card } from '../game/deck';
import type { Player } from '../game/player';
import { GameState, nextState, canDeal, canNewHand, showsEquity } from '../game/state';
import { createDeck, shuffle, drawCards } from '../game/deck';
import { createPlayers, dealHoleCards, updateEquities, clearEquities } from '../game/player';
import { calculateEquity } from '../game/equity';
import { determineWinners } from '../game/showdown';
import { loadPlayerCount, loadPlayerNames, loadSampleCount } from './storage';

export interface GameData {
  state: GameState;
  players: Player[];
  community: Card[];
  riverCard: Card | null;
  winners: number[];
  sampleCount: number;
}

export class GameController {
  private gameData: GameData;

  constructor(playerCount?: number) {
    const count = playerCount ?? loadPlayerCount();
    const savedNames = loadPlayerNames();

    const players = createPlayers(count);
    players.forEach(p => {
      p.name = savedNames[p.id] || p.name;
    });

    this.gameData = {
      state: GameState.Ready,
      players,
      community: [],
      riverCard: null,
      winners: [],
      sampleCount: loadSampleCount(),
    };
  }

  getState(): GameData {
    return this.gameData;
  }

  canDeal(): boolean {
    return canDeal(this.gameData.state);
  }

  canNewHand(): boolean {
    return canNewHand(this.gameData.state);
  }

  showsEquity(): boolean {
    return showsEquity(this.gameData.state);
  }

  /**
   * Process when DEAL button is pressed
   */
  async deal(): Promise<void> {
    if (!this.canDeal()) {
      throw new Error('Cannot DEAL in current state');
    }

    const currentState = this.gameData.state;
    const deck = shuffle(createDeck());

    // Exclude used cards
    const usedCards = new Set([
      ...this.gameData.community,
      ...this.gameData.players.flatMap(p => p.holeCards),
    ]);

    const availableDeck = deck.filter(c => !usedCards.has(c));

    switch (currentState) {
      case GameState.Ready:
        // Preflop: Deal hole cards to each player
        const holeCards = this.gameData.players.map(() => drawCards(availableDeck, 2) as [Card, Card]);
        dealHoleCards(this.gameData.players, holeCards);
        break;

      case GameState.PreflopDealt:
        // Flop: Deal 3 community cards
        this.gameData.community = drawCards(availableDeck, 3);
        break;

      case GameState.FlopDealt:
        // Turn: Add 1 card
        this.gameData.community.push(...drawCards(availableDeck, 1));
        break;

      case GameState.TurnDealt:
        // River: Save 1 card to riverCard (for squeeze)
        this.gameData.riverCard = drawCards(availableDeck, 1)[0];
        break;
    }

    this.gameData.state = nextState(currentState);

    // Calculate equity
    if (this.showsEquity()) {
      await this.calculateEquities();
    }
  }

  /**
   * Process when NEW HAND button is pressed
   */
  newHand(): void {
    if (!this.canNewHand()) {
      throw new Error('Cannot start NEW HAND in current state');
    }

    // Reset while keeping player names
    this.gameData.players.forEach(p => {
      p.holeCards = [];
      p.equity = undefined;
    });

    this.gameData.community = [];
    this.gameData.riverCard = null;
    this.gameData.winners = [];
    this.gameData.state = GameState.Ready;
  }

  /**
   * Reveal river card and transition to Showdown
   */
  revealRiver(): void {
    if (this.gameData.state !== GameState.RiverSqueeze || !this.gameData.riverCard) {
      throw new Error('Cannot reveal river card in current state');
    }

    this.gameData.community.push(this.gameData.riverCard);
    this.gameData.riverCard = null;
    this.gameData.state = GameState.Showdown;

    // Clear equity
    clearEquities(this.gameData.players);

    // Determine winners
    const result = determineWinners(this.gameData.players, this.gameData.community);
    this.gameData.winners = result.winners;
  }

  /**
   * Calculate equity
   */
  private async calculateEquities(): Promise<void> {
    const result = calculateEquity(
      this.gameData.players,
      this.gameData.community,
      this.gameData.sampleCount
    );
    updateEquities(this.gameData.players, result.equities);
  }

  /**
   * Change player count
   */
  setPlayerCount(count: number): void {
    const savedNames = loadPlayerNames();
    const players = createPlayers(count);
    players.forEach(p => {
      p.name = savedNames[p.id] || p.name;
    });

    this.gameData = {
      state: GameState.Ready,
      players,
      community: [],
      riverCard: null,
      winners: [],
      sampleCount: this.gameData.sampleCount,
    };
  }

  /**
   * Set player name
   */
  setPlayerName(playerId: number, name: string): void {
    const player = this.gameData.players.find(p => p.id === playerId);
    if (player) {
      player.name = name;
    }
  }

  /**
   * Set sample count
   */
  setSampleCount(count: number): void {
    this.gameData.sampleCount = count;
  }
}
