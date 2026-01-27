import { GameController } from './ui/app';
import {
  renderPlayers,
  renderCommunity,
  updateStateDisplay,
  updateButtons,
  showLoading,
  applyColorMode,
} from './ui/render';
import { initSqueeze, clearSqueeze } from './ui/squeeze';
import {
  loadPlayerCount,
  loadPlayerNames,
  loadColorMode,
  savePlayerCount,
  savePlayerNames,
  saveColorMode,
} from './ui/storage';
import { GameState } from './game/state';

let gameController: GameController;

async function initGame(): Promise<void> {
  const playerCount = loadPlayerCount();
  gameController = new GameController(playerCount);

  const colorMode = loadColorMode();
  applyColorMode(colorMode);

  updateGame();
}

function updateGame(): void {
  const state = gameController.getState();

  updateStateDisplay(state.state);
  updateButtons(gameController.canDeal(), gameController.canNewHand());

  renderPlayers(state.players, gameController.showsEquity(), state.winners);
  renderCommunity(state.community);

  // River Squeeze 状態の場合
  if (state.state === GameState.RiverSqueeze && state.riverCard) {
    initSqueeze(state.riverCard, () => {
      gameController.revealRiver();
      updateGame();
    });
  } else {
    clearSqueeze();
  }
}

async function handleDeal(): Promise<void> {
  try {
    showLoading(true);
    await gameController.deal();
    showLoading(false);
    updateGame();
  } catch (error) {
    showLoading(false);
    console.error('Failed to deal:', error);
    alert(`Error: ${error}`);
  }
}

function handleNewHand(): void {
  try {
    gameController.newHand();
    updateGame();
  } catch (error) {
    console.error('Failed to start new hand:', error);
    alert(`Error: ${error}`);
  }
}

function openSettings(): void {
  const modal = document.getElementById('settings-modal');
  if (!modal) return;

  modal.style.display = 'flex';

  // 現在の設定を反映
  const playerCountSelect = document.getElementById('player-count-select') as HTMLSelectElement;
  const colorModeSelect = document.getElementById('color-mode-select') as HTMLSelectElement;

  if (playerCountSelect) playerCountSelect.value = loadPlayerCount().toString();
  if (colorModeSelect) colorModeSelect.value = loadColorMode().toString();

  renderPlayerNameInputs();
}

function closeSettings(): void {
  const modal = document.getElementById('settings-modal');
  if (!modal) return;

  modal.style.display = 'none';
  saveSettings();
}

function renderPlayerNameInputs(): void {
  const container = document.getElementById('player-names-container');
  if (!container) return;

  container.innerHTML = '';

  const playerCountSelect = document.getElementById('player-count-select') as HTMLSelectElement;
  const playerCount = parseInt(playerCountSelect.value, 10);
  const savedNames = loadPlayerNames();

  for (let i = 1; i <= playerCount; i++) {
    const input = document.createElement('input');
    input.type = 'text';
    input.className = 'player-name-input';
    input.placeholder = `Player ${i}`;
    input.value = savedNames[i] || `Player ${i}`;
    input.dataset.playerId = i.toString();
    container.appendChild(input);
  }
}

function saveSettings(): void {
  const playerCountSelect = document.getElementById('player-count-select') as HTMLSelectElement;
  const colorModeSelect = document.getElementById('color-mode-select') as HTMLSelectElement;

  const playerCount = parseInt(playerCountSelect.value, 10);
  const colorMode = parseInt(colorModeSelect.value, 10);

  // プレイヤー名を収集
  const nameInputs = document.querySelectorAll('.player-name-input') as NodeListOf<HTMLInputElement>;
  const names: Record<number, string> = {};
  nameInputs.forEach(input => {
    const id = parseInt(input.dataset.playerId || '0', 10);
    names[id] = input.value || `Player ${id}`;
  });

  savePlayerCount(playerCount);
  saveColorMode(colorMode);
  savePlayerNames(names);

  applyColorMode(colorMode);

  // Update player count if changed
  const currentPlayerCount = gameController.getState().players.length;
  if (playerCount !== currentPlayerCount) {
    gameController.setPlayerCount(playerCount);
  }

  // Update player names (always apply to reflect name changes)
  Object.entries(names).forEach(([id, name]) => {
    gameController.setPlayerName(parseInt(id, 10), name);
  });

  // Refresh display
  updateGame();
}

document.addEventListener('DOMContentLoaded', () => {
  initGame();

  const dealBtn = document.getElementById('deal-btn');
  const newHandBtn = document.getElementById('new-hand-btn');
  const settingsBtn = document.getElementById('settings-btn');

  if (dealBtn) dealBtn.addEventListener('click', handleDeal);
  if (newHandBtn) newHandBtn.addEventListener('click', handleNewHand);
  if (settingsBtn) settingsBtn.addEventListener('click', openSettings);

  // モーダルイベント
  const closeBtn = document.querySelector('.close');
  if (closeBtn) closeBtn.addEventListener('click', closeSettings);

  window.addEventListener('click', e => {
    const modal = document.getElementById('settings-modal');
    if (e.target === modal) {
      closeSettings();
    }
  });

  // プレイヤー数変更時にプレイヤー名入力欄を更新
  const playerCountSelect = document.getElementById('player-count-select');
  if (playerCountSelect) {
    playerCountSelect.addEventListener('change', renderPlayerNameInputs);
  }
});
