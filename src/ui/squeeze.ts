import type { Card } from '../game/deck';

let squeezeActive = false;
let squeezeStartX = 0;
let squeezeStartY = 0;
let squeezeProgress = 0;

const REVEAL_THRESHOLD = 60; // Auto-complete at 60% reveal

export function initSqueeze(riverCard: Card, onReveal: () => void): void {
  const container = document.getElementById('river-card-container');
  if (!container) return;

  container.innerHTML = '';

  const cardDiv = document.createElement('div');
  cardDiv.className = 'squeeze-card card-back';
  cardDiv.id = 'squeeze-card';

  // Peel overlay
  const overlay = document.createElement('div');
  overlay.className = 'peel-overlay';
  cardDiv.appendChild(overlay);

  // Card content (initially hidden)
  const content = document.createElement('div');
  content.className = 'card-content';
  const suit = riverCard[1];
  content.innerHTML = `
    <div class="card-rank">${riverCard[0]}</div>
    <div class="card-suit suit-${suit}" data-suit="${suit}"></div>
  `;
  cardDiv.appendChild(content);

  container.appendChild(cardDiv);

  setupSqueezeEvents(cardDiv, overlay, content, onReveal);
}

function setupSqueezeEvents(
  cardDiv: HTMLElement,
  overlay: HTMLElement,
  content: HTMLElement,
  onReveal: () => void
): void {
  const handleStart = (e: MouseEvent | TouchEvent) => {
    e.preventDefault();
    squeezeActive = true;

    const pos = getEventPosition(e);
    squeezeStartX = pos.x;
    squeezeStartY = pos.y;
  };

  const handleMove = (e: MouseEvent | TouchEvent) => {
    if (!squeezeActive) return;
    e.preventDefault();

    const pos = getEventPosition(e);
    const deltaX = pos.x - squeezeStartX;
    const deltaY = pos.y - squeezeStartY;

    // Calculate peel distance from top-right corner
    const cardRect = cardDiv.getBoundingClientRect();
    const maxDistance = Math.sqrt(cardRect.width ** 2 + cardRect.height ** 2);
    const distance = Math.sqrt(deltaX ** 2 + deltaY ** 2);
    squeezeProgress = Math.min((distance / maxDistance) * 100, 100);

    // Update overlay and content display
    overlay.style.clipPath = `polygon(${100 - squeezeProgress}% 0, 100% 0, 100% ${squeezeProgress}%, ${100 - squeezeProgress}% ${squeezeProgress}%)`;
    content.style.opacity = `${squeezeProgress / 100}`;

    // Fully reveal card when over 60%
    if (squeezeProgress >= REVEAL_THRESHOLD) {
      completeReveal(cardDiv, overlay, content, onReveal);
    }
  };

  const handleEnd = () => {
    squeezeActive = false;
  };

  // Touch events
  cardDiv.addEventListener('touchstart', handleStart);
  cardDiv.addEventListener('touchmove', handleMove);
  cardDiv.addEventListener('touchend', handleEnd);

  // Mouse events
  cardDiv.addEventListener('mousedown', handleStart);
  cardDiv.addEventListener('mousemove', handleMove);
  cardDiv.addEventListener('mouseup', handleEnd);
}

function completeReveal(
  cardDiv: HTMLElement,
  overlay: HTMLElement,
  content: HTMLElement,
  onReveal: () => void
): void {
  squeezeActive = false;

  // Complete reveal with animation
  overlay.style.transition = 'clip-path 0.3s ease';
  overlay.style.clipPath = 'polygon(0 0, 100% 0, 100% 100%, 0 100%)';

  content.style.transition = 'opacity 0.3s ease';
  content.style.opacity = '1';

  cardDiv.classList.remove('card-back');

  // Transition to Showdown
  setTimeout(() => {
    onReveal();
  }, 300);
}

function getEventPosition(e: MouseEvent | TouchEvent): { x: number; y: number } {
  if ('touches' in e) {
    return {
      x: e.touches[0].clientX,
      y: e.touches[0].clientY,
    };
  }
  return {
    x: e.clientX,
    y: e.clientY,
  };
}

export function clearSqueeze(): void {
  const container = document.getElementById('river-card-container');
  if (container) {
    container.innerHTML = '';
  }
  squeezeActive = false;
  squeezeProgress = 0;
}
