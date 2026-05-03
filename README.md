# Flip-Out

**NLH Flip-Out Web Application with River Squeeze**

A No-Limit Hold'em (NLH) flip-out tool designed for quick, in-person use. Built with Flutter Web for optimal mobile experience.

## Features

- 🎲 **2-8 Players Support**: Flexible player count management
- 📊 **Equity Calculation**: Real-time win probability display at Preflop, Flop, and Turn
- 🎴 **River Squeeze Animation**: Baccarat-style card reveal experience (critical feature)
- 🎯 **Hand Highlighting**: Automatic identification of winning 5-card hands
- ⚙️ **Customizable Settings**: Player names and card color modes (2-color/4-color)
- 💾 **Persistent Settings**: LocalStorage-based configuration
- 📱 **Mobile-First Design**: Optimized for smartphone usage

## Technology Stack

- **Flutter Web**: For cross-platform web application
- **Dart**: Programming language
- **poker package**: For equity calculation and hand evaluation
- **Provider**: State management
- **SharedPreferences**: Local storage

## Game Flow (State Machine)

1. **S0 (Ready)**: No cards dealt
2. **S1 (Preflop)**: Hole cards dealt, equity shown
3. **S2 (Flop)**: 3 community cards revealed, equity shown
4. **S3 (Turn)**: 4th community card revealed, equity shown
5. **S4 (River Squeeze)**: River card hidden, squeeze interaction enabled
6. **S5 (Showdown)**: River revealed, winners highlighted

## Development

### Prerequisites

- Flutter SDK 3.19.0 or higher
- Dart SDK 3.0.0 or higher

### Setup

```bash
# Install dependencies
flutter pub get

# Run in development mode
flutter run -d chrome

# Build for production
flutter build web --release
```

### Project Structure

```
lib/
├── controllers/        # Game logic and state management
│   └── game_controller.dart
├── models/            # Data models
│   ├── game_state.dart
│   ├── player.dart
│   └── settings.dart
├── screens/           # UI screens
│   ├── main_screen.dart
│   └── settings_screen.dart
├── services/          # Business logic services
│   ├── deck_service.dart
│   ├── equity_service.dart
│   ├── hand_evaluator_service.dart
│   └── storage_service.dart
├── widgets/           # Reusable UI components
│   ├── playing_card.dart
│   └── river_squeeze.dart
└── main.dart          # Application entry point
```

## Deployment

This application is automatically deployed to GitHub Pages via GitHub Actions.

### Manual Deployment

```bash
# Build for GitHub Pages
flutter build web --release --base-href /flipout/

# The output will be in build/web/
```

## Requirements

See [docs/rdd.md](docs/rdd.md) for detailed requirements specification.

## License

MIT
