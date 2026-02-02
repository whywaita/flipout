import 'package:flutter/foundation.dart';
import 'package:poker/poker.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/settings.dart';
import '../services/deck_service.dart';
import '../services/equity_service.dart';
import '../services/hand_evaluator_service.dart';
import '../services/storage_service.dart';

/// Main game controller managing the state machine
class GameController extends ChangeNotifier {
  GameState _state = GameState.ready;
  Settings _settings = Settings();
  List<Player> _players = [];
  List<Card> _communityCards = [];
  Card? _riverCard;
  final DeckService _deckService = DeckService();
  bool _isCalculatingEquity = false;

  GameState get state => _state;
  Settings get settings => _settings;
  List<Player> get players => _players;
  List<Card> get communityCards => _communityCards;
  Card? get riverCard => _riverCard;
  bool get isCalculatingEquity => _isCalculatingEquity;

  GameController() {
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    // Load settings from storage
    final savedSettings = await StorageService.loadSettings();
    if (savedSettings != null) {
      _settings = savedSettings;
    }

    // Initialize players
    _initializePlayers();
    notifyListeners();
  }

  void _initializePlayers() {
    _players = List.generate(
      _settings.playerCount,
      (i) => Player(
        index: i,
        name: i < _settings.playerNames.length
            ? _settings.playerNames[i]
            : 'Player ${i + 1}',
      ),
    );
  }

  /// Update settings and save to storage
  Future<void> updateSettings(Settings newSettings) async {
    _settings = newSettings;
    await StorageService.saveSettings(_settings);

    // Update player names
    for (int i = 0; i < _players.length && i < _settings.playerNames.length; i++) {
      _players[i].name = _settings.playerNames[i];
    }

    notifyListeners();
  }

  /// Change player count (only allowed in Preflop state)
  void changePlayerCount(int count) {
    if (_state != GameState.preflopDealt) {
      throw StateError('Player count can only be changed in Preflop state');
    }

    if (count < 2 || count > 8) {
      throw ArgumentError('Player count must be between 2 and 8');
    }

    _settings = _settings.copyWith(playerCount: count);
    _initializePlayers();

    // Re-deal cards for new player count
    _dealPreflop();
  }

  /// Handle DEAL button press
  Future<void> onDeal() async {
    switch (_state) {
      case GameState.ready:
        _dealPreflop();
        break;
      case GameState.preflopDealt:
        await _dealFlop();
        break;
      case GameState.flopDealt:
        await _dealTurn();
        break;
      case GameState.turnDealt:
        _prepareRiver();
        break;
      case GameState.riverSqueeze:
        // DEAL is disabled during squeeze
        break;
      case GameState.showdown:
        // DEAL has no effect
        break;
    }
  }

  void _dealPreflop() {
    _deckService.reset();
    _communityCards.clear();
    _riverCard = null;

    // Deal 2 hole cards to each player
    for (final player in _players) {
      player.holeCards = _deckService.drawCards(2);
      player.equity = null;
      player.isWinner = false;
      player.winningHand = null;
    }

    _state = GameState.preflopDealt;
    notifyListeners();

    // Calculate equity
    _calculateEquity();
  }

  Future<void> _dealFlop() async {
    // Deal 3 cards
    _communityCards = _deckService.drawCards(3);
    _state = GameState.flopDealt;
    notifyListeners();

    // Calculate equity
    await _calculateEquity();
  }

  Future<void> _dealTurn() async {
    // Deal 1 card
    _communityCards.add(_deckService.drawCard());
    _state = GameState.turnDealt;
    notifyListeners();

    // Calculate equity
    await _calculateEquity();
  }

  void _prepareRiver() {
    // Draw river card but keep it hidden
    _riverCard = _deckService.drawCard();
    _state = GameState.riverSqueeze;

    // Clear equity (not shown on River)
    for (final player in _players) {
      player.equity = null;
    }

    notifyListeners();
  }

  /// Complete the river squeeze and show results
  Future<void> completeRiverSqueeze() async {
    if (_state != GameState.riverSqueeze || _riverCard == null) {
      return;
    }

    // Add river card to community cards
    _communityCards.add(_riverCard!);
    _state = GameState.showdown;
    notifyListeners();

    // Evaluate hands and determine winners
    await _evaluateShowdown();
  }

  Future<void> _calculateEquity() async {
    _isCalculatingEquity = true;
    notifyListeners();

    try {
      final equities = await EquityService.calculateEquity(
        players: _players,
        communityCards: _communityCards,
        simulations: _communityCards.isEmpty ? 10000 : 50000,
      );

      for (final entry in equities.entries) {
        _players[entry.key].equity = entry.value;
      }
    } catch (e) {
      debugPrint('Error calculating equity: $e');
    } finally {
      _isCalculatingEquity = false;
      notifyListeners();
    }
  }

  Future<void> _evaluateShowdown() async {
    try {
      final winners = await HandEvaluatorService.evaluateShowdown(
        players: _players,
        communityCards: _communityCards,
      );

      // Reset all players to not winners
      for (final player in _players) {
        player.isWinner = false;
        player.winningHand = null;
      }

      // Mark winners
      for (final winner in winners) {
        _players[winner.index].isWinner = true;
        _players[winner.index].winningHand = winner.winningHand;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error evaluating showdown: $e');
    }
  }

  /// Start a new hand
  void newHand() {
    _state = GameState.ready;
    _communityCards.clear();
    _riverCard = null;

    for (final player in _players) {
      player.holeCards = [];
      player.equity = null;
      player.isWinner = false;
      player.winningHand = null;
    }

    notifyListeners();
  }
}
