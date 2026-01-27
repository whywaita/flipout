import type { Card } from '../game/deck';
import type { Player } from '../game/player';
import { GameState, stateToString } from '../game/state';
import { formatEquity } from '../game/equity';

/**
 * Create card element
 */
export function createCardElement(card: Card, highlight = false): HTMLDivElement {
  const div = document.createElement('div');
  const suit = card[1];
  div.className = `card suit-${suit}`;

  if (highlight) {
    div.classList.add('highlight');
  }

  const rank = document.createElement('div');
  rank.className = 'card-rank';
  rank.textContent = card[0];

  const suitEl = document.createElement('div');
  suitEl.className = 'card-suit';
  suitEl.setAttribute('data-suit', suit);

  div.appendChild(rank);
  div.appendChild(suitEl);

  return div;
}

/**
 * Create card back
 */
export function createCardBack(): HTMLDivElement {
  const div = document.createElement('div');
  div.className = 'card card-back';
  return div;
}

/**
 * Update player display
 */
export function renderPlayers(
  players: Player[],
  showsEquity: boolean,
  winners: number[]
): void {
  const container = document.getElementById('players-container');
  if (!container) return;

  container.innerHTML = '';

  // Set class according to player count
  const playerCount = players.length;
  container.className = `players-${playerCount}`;

  players.forEach((player) => {
    // Seat wrapper
    const seatDiv = document.createElement('div');
    seatDiv.className = 'player-seat';

    // Player card
    const playerDiv = document.createElement('div');
    playerDiv.className = 'player-card';

    if (winners.includes(player.id)) {
      playerDiv.classList.add('winner');
    }

    const name = document.createElement('div');
    name.className = 'player-name';
    name.textContent = player.name;
    playerDiv.appendChild(name);

    // Equity display
    if (showsEquity && player.equity !== undefined) {
      const equity = document.createElement('div');
      equity.className = 'player-equity';
      equity.textContent = formatEquity(player.equity);
      playerDiv.appendChild(equity);
    }

    // Hole cards
    const cardsDiv = document.createElement('div');
    cardsDiv.className = 'player-cards';

    if (player.holeCards.length === 2) {
      player.holeCards.forEach(card => {
        const cardEl = createCardElement(card);
        cardsDiv.appendChild(cardEl);
      });
    }

    playerDiv.appendChild(cardsDiv);
    seatDiv.appendChild(playerDiv);
    container.appendChild(seatDiv);
  });
}

/**
 * Update community cards display
 */
export function renderCommunity(community: Card[]): void {
  const container = document.getElementById('community-cards');
  if (!container) return;

  container.innerHTML = '';

  community.forEach(card => {
    const cardEl = createCardElement(card);
    container.appendChild(cardEl);
  });
}

/**
 * Update state display
 */
export function updateStateDisplay(state: GameState): void {
  const display = document.getElementById('state-display');
  if (!display) return;

  display.textContent = `State: ${stateToString(state)}`;
}

/**
 * Update button enabled/disabled state
 */
export function updateButtons(canDeal: boolean, canNewHand: boolean): void {
  const dealBtn = document.getElementById('deal-btn') as HTMLButtonElement;
  const newHandBtn = document.getElementById('new-hand-btn') as HTMLButtonElement;

  if (dealBtn && newHandBtn) {
    // DEAL and NEW HAND are mutually exclusive
    if (canNewHand) {
      dealBtn.style.display = 'none';
      newHandBtn.style.display = 'inline-block';
      newHandBtn.disabled = false;
    } else {
      dealBtn.style.display = 'inline-block';
      newHandBtn.style.display = 'none';
      dealBtn.disabled = !canDeal;
    }
  }
}

/**
 * Toggle loading display
 */
export function showLoading(show: boolean): void {
  const loading = document.getElementById('loading');
  if (loading) {
    loading.style.display = show ? 'flex' : 'none';
  }
}

/**
 * Apply color mode
 */
export function applyColorMode(mode: number): void {
  document.body.classList.remove('color-2', 'color-4');
  document.body.classList.add(`color-${mode}`);
}
