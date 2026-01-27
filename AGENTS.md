# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NLH Flip-Out is a No-Limit Hold'em flip-out web application optimized for mobile devices. It simulates poker flip-out scenarios with 2-8 players, calculates equity (win probability) using Monte Carlo simulation, and features a Baccarat-style squeeze animation for revealing the river card.

**Tech Stack**: TypeScript, Vite, phe (poker hand evaluator library)

## Development Commands

```bash
# Install dependencies
npm install

# Start development server (http://localhost:5173/flipout/)
npm run dev

# Run all tests
npm test

# Run tests in watch mode
npm test -- --watch

# Build for production
npm run build

# Preview production build
npm preview
```

## Architecture

### State Machine

The application is built around a **strict state machine** (see `src/game/state.ts`):

| State | Description | DEAL Action | NEW HAND |
|-------|-------------|-------------|----------|
| `Ready` (S0) | No cards dealt | Deal hole cards → PreflopDealt | N/A |
| `PreflopDealt` (S1) | Hole cards dealt, equity shown | Deal flop → FlopDealt | Available |
| `FlopDealt` (S2) | Flop revealed, equity shown | Deal turn → TurnDealt | Available |
| `TurnDealt` (S3) | Turn revealed, equity shown | Prepare river → RiverSqueeze | Available |
| `RiverSqueeze` (S4) | River hidden, squeeze in progress | **DISABLED** | Available |
| `Showdown` (S5) | River revealed, winners shown | N/A | Available |

**Critical**: The DEAL button must be disabled during `RiverSqueeze` state to prevent state conflicts.

### Module Organization

```
src/
├── game/              # Pure game logic (deck, state, equity, showdown)
│   ├── deck.ts        # Card operations, shuffling
│   ├── state.ts       # State machine definitions
│   ├── player.ts      # Player management
│   ├── equity.ts      # Monte Carlo simulation (10,000 samples default)
│   ├── evaluator.ts   # phe library wrapper for hand evaluation
│   └── showdown.ts    # Winner determination
├── ui/                # UI layer (render, events, storage)
│   ├── app.ts         # GameController - main orchestrator
│   ├── render.ts      # DOM manipulation functions
│   ├── squeeze.ts     # River card squeeze animation
│   └── storage.ts     # LocalStorage persistence
└── main.ts            # Entry point, event handlers
```

### Data Flow

1. **User Action** → `main.ts` event handlers
2. **GameController** (`ui/app.ts`) → Updates game state, calls game logic
3. **Game Logic** (`game/*`) → Pure functions, no side effects
4. **Render** (`ui/render.ts`) → Updates DOM based on new state

**Key Pattern**: `GameController` holds `GameData` and exposes methods like `deal()`, `newHand()`, `revealRiver()`. After any state change, call `updateGame()` in `main.ts` to refresh the entire UI.

### Equity Calculation

Equity is calculated using **Monte Carlo simulation** (see `src/game/equity.ts`):
- Simulates remaining community cards (default: 10,000 samples)
- Uses `phe` library for fast 7-card hand evaluation (~7-10M hands/sec)
- Returns equity array for all players
- **Displayed**: Preflop, Flop, Turn
- **Hidden**: River, Showdown

### River Squeeze Animation

The river reveal uses a drag-based "squeeze" animation (`src/ui/squeeze.ts`):
- User drags from top-right corner to peel the card
- Overlay clips progressively to reveal card content
- Auto-completes at 60% reveal threshold
- Transitions from `RiverSqueeze` → `Showdown` on completion

**Touch & Mouse Events**: Both are handled for mobile and desktop compatibility.

## Important Constraints

### Player Count Changes

- **Only allowed in `Ready` or `PreflopDealt` states** (see `canChangePlayerCount()` in `state.ts`)
- Player names must be preserved when count changes
- Always call `updateGame()` after changing settings to reflect changes in the UI

### Settings Persistence

All settings are stored in `LocalStorage`:
- Player count
- Player names (keyed by player ID)
- Card color mode (2-color or 4-color)
- Sample count for equity calculation

**Pattern**: Save settings in `storage.ts`, load on app initialization in `main.ts`.

### UI Update Pattern

After any game state mutation:
1. Call `gameController.method()` to update internal state
2. Call `updateGame()` to refresh all UI components
3. Components read from `gameController.getState()` and re-render

**Example**:
```typescript
gameController.deal();
updateGame(); // Re-renders players, community, buttons, etc.
```

## Common Patterns

### Adding a New Game State

1. Add enum value to `GameState` in `src/game/state.ts`
2. Update `nextState()` transition logic
3. Update `canDeal()`, `canNewHand()`, `showsEquity()` as needed
4. Add switch case in `GameController.deal()` if state has deal logic
5. Update `updateGame()` in `main.ts` if special rendering is needed

### Modifying Equity Display

Equity calculation happens in `GameController.deal()` after state transitions. To change:
- Adjust sample count in `src/game/equity.ts` (default: 10,000)
- Modify `showsEquity()` logic in `state.ts` to control visibility
- Format changes: edit `formatEquity()` in `equity.ts`

### Player Position Layout

Player positioning is **CSS-based** using absolute positioning:
- See `styles/main.css` for `.players-{2-8}` classes
- Each player count has predefined `.player-seat:nth-child(n)` positions
- Positions are percentage-based for responsive layout

## Testing

Tests are written using Vitest and located in `tests/`:
- `deck.test.ts` - Deck operations, card conversions
- `equity.test.ts` - Monte Carlo simulation accuracy
- `showdown.test.ts` - Winner determination logic

**Run a single test file**:
```bash
npm test tests/equity.test.ts
```

## Deployment

- GitHub Actions auto-deploys to GitHub Pages on push to `main`
- Build output goes to `dist/` directory
- Base path is `/flipout/` (configured in `vite.config.ts`)

## Language

All code, comments, and error messages are in **English**. Japanese is only used in user-facing display text if needed.
