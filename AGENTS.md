# AGENTS.md

This file provides guidance to AI agents (including Claude Code) when working with code in this repository.

## Project Overview

NLH Flip-Out is a No-Limit Hold'em flip-out web application optimized for mobile devices. It simulates poker flip-out scenarios with 2-8 players, calculates equity (win probability) using Monte Carlo simulation, and features a Baccarat-style squeeze animation for revealing the river card.

**Tech Stack**: Flutter Web (Dart), poker package (pub.dev)

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Format code
dart format lib/ test/

# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Start development server (Chrome)
flutter run -d chrome

# Build for production (Web)
flutter build web --release

# Build for production with base-href (GitHub Pages)
flutter build web --release --base-href /flipout/
```

## Architecture

### State Machine

The application is built around a **strict state machine** (see `lib/models/game_state.dart`):

| State | Description | DEAL Action | NEW HAND |
|-------|-------------|-------------|----------|
| `ready` (S0) | No cards dealt | Deal hole cards → preflopDealt | N/A |
| `preflopDealt` (S1) | Hole cards dealt, equity shown | Deal flop → flopDealt | Available |
| `flopDealt` (S2) | Flop revealed, equity shown | Deal turn → turnDealt | Available |
| `turnDealt` (S3) | Turn revealed, equity shown | Prepare river → riverSqueeze | Available |
| `riverSqueeze` (S4) | River hidden, squeeze in progress | **DISABLED** | Available |
| `showdown` (S5) | River revealed, winners shown | N/A | Available |

**Critical**: The DEAL button must be disabled during `riverSqueeze` state to prevent state conflicts.

### Module Organization

```
lib/
├── controllers/                    # State management
│   └── game_controller.dart       # Main game controller (ChangeNotifier)
├── models/                         # Data models
│   ├── game_state.dart            # GameState enum (state machine)
│   ├── player.dart                # Player model with copyWith()
│   └── settings.dart              # Settings model (serializable)
├── screens/                        # UI screens
│   ├── main_screen.dart           # Main game screen
│   └── settings_screen.dart       # Settings screen
├── services/                       # Business logic (pure functions)
│   ├── deck_service.dart          # Deck management, shuffling
│   ├── equity_service.dart        # Monte Carlo simulation (poker package)
│   ├── hand_evaluator_service.dart # Winner determination using poker package
│   └── storage_service.dart       # SharedPreferences wrapper
├── widgets/                        # Reusable UI components
│   ├── playing_card.dart          # Card display widget
│   └── river_squeeze.dart         # River squeeze animation (CustomPainter + GestureDetector)
└── main.dart                       # Entry point, Provider setup
```

### Data Flow

1. **User Action** → Widget event handlers (e.g., onPressed)
2. **GameController** → Updates internal state, calls services
3. **Services** → Pure business logic (deck, equity, hand evaluation)
4. **notifyListeners()** → Triggers widget rebuild
5. **Widgets** → Read from Provider, rebuild with new state

**Key Pattern**:
- `GameController extends ChangeNotifier` holds all game state
- Services are stateless and called by controller
- Widgets use `Provider.of<GameController>(context)` to access state
- All state mutations go through controller methods

### Equity Calculation

Equity is calculated using **Monte Carlo simulation** (see `lib/services/equity_service.dart`):
- Uses `poker` package's `MontecarloEvaluator`
- Default samples: 10,000 (preflop), 50,000 (flop/turn)
- Simulates all possible remaining community cards
- Returns equity percentage (0-100) for each player
- **Displayed**: Preflop, Flop, Turn
- **Hidden**: River, Showdown

**Implementation Notes**:
- Card format conversion: Card object → "AsKh" string format
- HandRange parsing for each player's hole cards
- ImmutableCardSet for community cards

### River Squeeze Animation

The river reveal uses a drag-based "squeeze" animation (`lib/widgets/river_squeeze.dart`):
- Implemented with `CustomPainter` and `CustomClipper`
- User drags vertically to peel the card
- `GestureDetector.onPanUpdate` tracks drag progress
- Overlay clips progressively using `_SqueezeClipper`
- Auto-completes at 60% reveal threshold
- Corner hint appears at 10% reveal
- Transitions from `riverSqueeze` → `showdown` on completion

**Touch & Drag**: Works on both mobile (touch) and desktop (mouse) via GestureDetector.

## Important Constraints

### Player Count Changes

- **Only allowed in `preflopDealt` state** (see `changePlayerCount()` in `game_controller.dart`)
- Throws `StateError` if called in other states
- Player names are preserved from settings
- Automatically re-deals cards for new player count

### Settings Persistence

All settings are stored in `SharedPreferences`:
- Player count (2-8)
- Player names (List<String>)
- Card color mode (2-color or 4-color)

**Pattern**:
- Load: `StorageService.loadSettings()` → `Settings?`
- Save: `StorageService.saveSettings(Settings)` → `Future<void>`
- JSON serialization: `Settings.toJson()` / `Settings.fromJson()`

### UI Update Pattern

Flutter's reactive pattern handles UI updates automatically:
1. Call `gameController.method()` to update state
2. Controller calls `notifyListeners()`
3. All listening widgets rebuild automatically
4. No manual refresh needed

**Example**:
```dart
// In widget
final controller = Provider.of<GameController>(context);
controller.onDeal(); // Automatically triggers rebuild
```

## Common Patterns

### Adding a New Game State

1. Add enum value to `GameState` in `lib/models/game_state.dart`
2. Update transition logic in `GameController.onDeal()`
3. Add handling in `GameController._dealPreflop()`, `_dealFlop()`, etc.
4. Update conditional rendering in `main_screen.dart`
5. Test state transitions thoroughly

### Modifying Equity Display

Equity calculation happens in `GameController._calculateEquity()` after state transitions. To change:
- Adjust sample count in `equity_service.dart` (currently: 10,000 for preflop, 50,000 for flop/turn)
- Simulations parameter is passed to `MontecarloEvaluator`
- Display logic is in `main_screen.dart` (checks if `player.equity != null`)

### Adding New Tests

Follow TDD (Red-Green-Refactor) cycle:
1. Write failing test first
2. Implement minimal code to pass
3. Refactor for quality

**Test Structure**:
```
test/
├── models/            # Model tests (copyWith, serialization)
├── services/          # Service tests (pure function logic)
├── controllers/       # Controller tests (state transitions)
└── widgets/           # Widget tests (UI behavior)
```

**Important**: Use `setUp()` to initialize SharedPreferences mock:
```dart
setUp(() async {
  SharedPreferences.setMockInitialValues({});
  controller = GameController();
  await Future.delayed(const Duration(milliseconds: 100));
});
```

## Testing

Tests are written using flutter_test and located in `test/`:
- `test/services/deck_service_test.dart` - Deck operations, shuffling
- `test/services/hand_evaluator_service_test.dart` - Winner determination
- `test/controllers/game_controller_test.dart` - State machine transitions
- `test/models/player_test.dart` - Player model behavior
- `test/models/settings_test.dart` - Settings serialization

**Run specific tests**:
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/deck_service_test.dart

# Run with coverage
flutter test --coverage
```

**Current Test Status**: 20 tests passing ✓

## Deployment

### GitHub Actions Workflows

Three workflows are configured:

1. **CI** (`.github/workflows/ci.yml`):
   - Runs on: push to main, pull requests
   - Steps: analyze, test, build web
   - Ensures code quality before merge

2. **Build Check** (`.github/workflows/build-check.yml`):
   - Runs on: all pushes and PRs
   - Quick build validation

3. **Deploy to GitHub Pages** (`.github/workflows/deploy-pages.yml`):
   - Runs on: push to main
   - Auto-deploys to GitHub Pages
   - URL: `https://whywaita.github.io/flipout/`

### Manual Deployment

```bash
# Build for GitHub Pages
flutter build web --release --base-href /flipout/

# Output: build/web/
```

## Important Notes for AI Agents

### Code Style

- **Run `dart format` before committing** (required by user's CLAUDE.md rules)
- Follow Dart/Flutter conventions (lowerCamelCase, avoid magic numbers)
- Use const constructors where possible
- Keep functions small and focused

### API Changes (poker package)

When using the `poker` package (v0.10.0), note:
- Card constructor: `Card(rank, suit)` (positional, NOT named)
- Rank enum: Use `Rank.deuce` (not `Rank.two`), `Rank.trey` (not `Rank.three`)
- ImmutableCardSet:
  - Empty: `ImmutableCardSet.empty()` (const)
  - From iterable: `ImmutableCardSet.of(cards)`
  - From string: `ImmutableCardSet.parse('AsKh')`

### Type Conflicts

- `import 'package:flutter/material.dart' hide Card;` to avoid conflict with poker's Card
- Always use poker's Card class in game logic

### Deprecated APIs

- Use `.withValues(alpha: 0.5)` instead of `.withOpacity(0.5)` (Flutter 3.27+)

## Language

All code, comments, and error messages are in **English**. Japanese is only used in user-facing display text if needed.
