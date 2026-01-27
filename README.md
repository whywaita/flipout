# NLH Flip-Out

No-Limit Hold'em Flip-Out Web Application

## Overview

A web application that recreates No-Limit Hold'em flip-out games.
Calculates equity at Preflop, Flop, and Turn stages,
and reveals the River card with a squeeze animation.

## Tech Stack

- TypeScript
- Vite
- phe (high-performance poker hand evaluation library)
- Monte Carlo simulation

## Features

- **Fast Equity Calculation**: 7-10M hands/sec evaluation speed with phe library
- **Monte Carlo Simulation**: Default 10,000 iterations (~11ms for 8-player games)
- **Mobile-First**: Touch-enabled squeeze animation
- **2-8 Players**: Flexible player count configuration
- **Persistent Settings**: Player names and color mode saved to LocalStorage

## Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Run tests
npm test

# Production build
npm run build
```

## Deployment

Automatically deployed to GitHub Pages via GitHub Actions.

## Project Structure

```
flipout/
├── src/
│   ├── game/          # Game logic
│   ├── ui/            # UI-related
│   ├── types/         # TypeScript type definitions
│   └── main.ts        # Entry point
├── styles/            # CSS
├── tests/             # Tests
└── index.html         # Main HTML
```

## License

MIT
