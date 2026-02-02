# Requirements Specification

**NLH Flip-Out Web Application with River Squeeze**
*(Flutter Web / GitHub Pages / Mobile-first)*

---

## 1. Overview

This application is a **No-Limit Hold’em (NLH) flip-out tool** designed for quick, in-person use.
Users can flip out hands for **2–8 players**, view **equity (win probability)** during Preflop, Flop, and Turn, and reveal the River using a **Baccarat-style squeeze animation**.

The app is:

* Fully client-side (static)
* Hosted on **GitHub Pages**
* Implemented in **Flutter Web (Dart)**
* Optimized primarily for **smartphone usage**

---

## 2. Core Principles

* **Minimal interaction**:
  Outside of the settings screen, the user interacts only via:

  * **DEAL** button
  * **NEW HAND** button
* **Equity visibility**:

  * Shown at **Preflop, Flop, and Turn**
  * **Not shown on River**
* **River experience is critical**:

  * River card must be revealed using a **Baccarat-style squeeze**
  * Visual and tactile quality is a top priority
* **All hole cards are always face-up**

---

## 3. Supported Game Format

* Game: Texas Hold’em (No-Limit)
* Players: **2–8**
* One community board
* One run only (no multiple boards)

---

## 4. Screens

### 4.1 Main Screen

* Board area (Flop / Turn / River)
* Player list (2–8 rows)
* DEAL button (primary action)
* NEW HAND button
* Settings button (icon)

### 4.2 Settings Screen

* Player name editing
* Card color mode selection (2-color / 4-color)
* Settings are persisted via **LocalStorage**

---

## 5. State Machine

The application must be implemented as a **strict state machine**.

### 5.1 States

| State ID | Name         | Description                            |
| -------- | ------------ | -------------------------------------- |
| S0       | Ready        | No cards dealt                         |
| S1       | PreflopDealt | Hole cards dealt, Preflop equity shown |
| S2       | FlopDealt    | Flop revealed, Flop equity shown       |
| S3       | TurnDealt    | Turn revealed, Turn equity shown       |
| S4       | RiverSqueeze | River card hidden, squeeze in progress |
| S5       | Showdown     | River revealed, hand results displayed |

---

## 6. DEAL Button Behavior

| Current State | DEAL Result                               |
| ------------- | ----------------------------------------- |
| S0            | Deal 2 hole cards to each player → S1     |
| S1            | Reveal Flop (3 cards) → S2                |
| S2            | Reveal Turn (1 card) → S3                 |
| S3            | Prepare River and enter squeeze mode → S4 |
| S4            | DEAL disabled                             |
| S5            | DEAL optional / no effect                 |

---

## 7. Player Management

### 7.1 Player Count

* Minimum: 2
* Maximum: 8
* **Player count can be increased or decreased only in S1 (Preflop)**
* Player controls must be disabled or hidden in all other states

### 7.2 Player Names

* Default names:

  * `Player 1`, `Player 2`, …
* Editable in Settings screen
* Persisted in LocalStorage

### 7.3 Hole Cards

* Always **face-up**
* Automatically dealt by the system
* No manual card input

---

## 8. Card Dealing Rules

* Standard 52-card deck
* No duplicates
* Cards are drawn randomly
* Dealing order:

  1. Hole cards (2 per player)
  2. Flop (3)
  3. Turn (1)
  4. River (1)

---

## 9. Equity (Win Probability)

### 9.1 Display Rules

* **Displayed at**:

  * Preflop
  * Flop
  * Turn
* **Not displayed at River**

### 9.2 Calculation Library

* Use **`poker` package (pub.dev)**
* Calculations are performed in Dart (Monte Carlo simulation)

#### Usage Concept

* Preflop:

  * Evaluate equity using hole cards only
* Flop / Turn:

  * Evaluate equity using hole cards + community cards
* Equity values returned by the library are displayed per player

### 9.3 Display Format

* Percentage format (e.g., `34.6%`)
* Precision may be chosen by the implementation (recommended: 0.1% or 0.01%)

---

## 10. River Squeeze (Critical Feature)

### 10.1 Purpose

The River reveal is not a simple card flip.
It must recreate the **emotional experience of a Baccarat squeeze**.

This feature has **highest priority**.

---

### 10.2 Squeeze Rules

* Applies **only to the River card**
* Initial state:

  * River card is fully face-down
* Interaction:

  * **User drags the card to peel only the corner**
  * As the drag progresses, the corner reveals:

    * Rank
    * Suit
* No buttons are used during squeeze
* DEAL button is disabled during squeeze

---

### 10.3 Completion Conditions

* When reveal progress exceeds a defined threshold (e.g. ~60%)
* Card snaps to fully revealed state
* Application transitions from **S4 → S5 (Showdown)**

---

### 10.4 Visual Requirements

* Card design should evoke **Baccarat squeeze aesthetics**

  * Thick card stock feel
  * Shadows and depth
  * Emphasis on corner reveal
* Card color mode (2-color / 4-color) must still apply

---

## 11. Showdown & Hand Highlighting

### 11.1 Hand Evaluation

* After River is revealed:

  * All hands are evaluated
  * Winner(s) are determined

### 11.2 Single Winner

* Winning player row is highlighted
* **Only the 5 cards used in the winning made hand** are highlighted

  * Includes hole cards and/or board cards

### 11.3 Split Pot (Tie)

* All tied players are highlighted
* **For each player individually**:

  * Only the cards that make up *that player’s* made hand are highlighted
* Highlight sets may differ between tied players

---

## 12. NEW HAND Behavior

* NEW HAND button is allowed
* Resets:

  * Deck
  * Hole cards
  * Board
  * Equity display
  * Showdown highlights
  * Squeeze state
* Preserves:

  * Player count
  * Player names
  * Card color mode

---

## 13. Settings Persistence

* Stored via **LocalStorage**
* Restored on page load:

  * Player names
  * Player count
  * Card color mode

---

## 14. Non-Functional Requirements

### 14.1 Platform

* Mobile-first (iOS Safari, Android Chrome)
* Desktop support is secondary

### 14.2 Performance

* Equity calculation should feel responsive
* Turn equity must be near-instant
* Flop equity may take longer but must show a loading state if needed

### 14.3 Deployment

* Static hosting on GitHub Pages
* No backend services

---

## 15. Acceptance Criteria

* Players can be set between 2 and 8 (only during Preflop)
* DEAL button alone advances game flow
* Preflop, Flop, and Turn equity are displayed
* River equity is not displayed
* River is revealed using a drag-based squeeze animation
* Showdown highlights correct made-hand cards
* Split pots highlight per-player hand cards correctly
* Settings persist via LocalStorage
* App runs fully on GitHub Pages

---

## 16. Implementation Notes (For AI Agent)

* Use a centralized state machine (GameController with Provider)
* Flutter/Dart handles:

  * Deck management (DeckService)
  * Equity calculation (EquityService using poker package)
  * Hand evaluation (HandEvaluatorService)
  * UI rendering (Flutter widgets)
  * Animations (River squeeze using CustomPainter and GestureDetector)
  * Touch/drag interactions (GestureDetector)
* Architecture:

  * State management: Provider with ChangeNotifier
  * Services layer: Business logic separated from UI
  * Models: Immutable data structures with copyWith()
  * Widgets: Reusable components (PlayingCard, RiverSqueeze)
* River squeeze quality is more important than visual perfection elsewhere
