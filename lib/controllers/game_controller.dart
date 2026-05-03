import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/card_color_mode.dart';
import '../models/game_phase.dart';
import '../models/player.dart';
import '../models/playing_card.dart';
import '../models/settings.dart';
import '../services/deck_service.dart';
import '../services/equity_service.dart';
import '../services/hand_evaluator_service.dart';
import '../services/storage_service.dart';

class GameController extends ChangeNotifier {
  GameController({
    DeckService? deckService,
    EquityCalculator? equityService,
    HandEvaluatorService? handEvaluatorService,
    SettingsStorage? storageService,
  }) : _deckService = deckService ?? DeckService(),
       _equityService = equityService ?? const EquityService(),
       _handEvaluatorService =
           handEvaluatorService ?? const HandEvaluatorService(),
       _storageService = storageService ?? SharedPreferencesSettingsStorage() {
    _settings = AppSettings.defaults();
    _players = _playersFromSettings(_settings);
  }

  static const squeezeCompletionThreshold = 0.6;

  final DeckService _deckService;
  final EquityCalculator _equityService;
  final HandEvaluatorService _handEvaluatorService;
  final SettingsStorage _storageService;

  late AppSettings _settings;
  late List<Player> _players;
  List<PlayingCard> _board = [];
  PlayingCard? _hiddenRiverCard;
  GamePhase _phase = GamePhase.ready;
  bool _isCalculatingEquity = false;
  double _squeezeProgress = 0;
  int _equityGeneration = 0;

  GamePhase get phase => _phase;
  List<Player> get players => List.unmodifiable(_players);
  List<PlayingCard> get board => List.unmodifiable(_board);
  PlayingCard? get hiddenRiverCard => _hiddenRiverCard;
  CardColorMode get cardColorMode => _settings.cardColorMode;
  bool get isCalculatingEquity => _isCalculatingEquity;
  double get squeezeProgress => _squeezeProgress;

  bool get showPlayerCountControls => _phase == GamePhase.preflopDealt;

  bool get showEquity {
    return _phase == GamePhase.preflopDealt ||
        _phase == GamePhase.flopDealt ||
        _phase == GamePhase.turnDealt;
  }

  bool get canDeal {
    return _phase == GamePhase.ready ||
        _phase == GamePhase.preflopDealt ||
        _phase == GamePhase.flopDealt ||
        _phase == GamePhase.turnDealt;
  }

  bool get canStartNewHand => _phase == GamePhase.showdown;

  Future<void> loadSettings() async {
    _settings = await _storageService.load();
    _players = _playersFromSettings(_settings);
    notifyListeners();
  }

  Future<void> deal() async {
    switch (_phase) {
      case GamePhase.ready:
        await _dealHoleCards();
        return;
      case GamePhase.preflopDealt:
        await _dealFlop();
        return;
      case GamePhase.flopDealt:
        await _dealTurn();
        return;
      case GamePhase.turnDealt:
        _prepareRiverSqueeze();
        return;
      case GamePhase.riverSqueeze:
      case GamePhase.showdown:
        return;
    }
  }

  void incrementPlayers() {
    _changePlayerCount(1);
  }

  void decrementPlayers() {
    _changePlayerCount(-1);
  }

  Future<void> updatePlayerName(int index, String value) async {
    if (index < 0 || index >= 8) {
      return;
    }

    final names = List<String>.from(_settings.playerNames);
    while (names.length < 8) {
      names.add('Player ${names.length + 1}');
    }

    names[index] = _normalizePlayerName(index, value);
    _settings = _settings.copyWith(playerNames: names);
    _players = _players
        .asMap()
        .entries
        .map(
          (entry) => entry.value.copyWith(name: _settings.nameFor(entry.key)),
        )
        .toList();
    notifyListeners();
    await _persistSettings();
  }

  Future<void> updateCardColorMode(CardColorMode mode) async {
    _settings = _settings.copyWith(cardColorMode: mode);
    notifyListeners();
    await _persistSettings();
  }

  void updateSqueezeProgress(double progress) {
    if (_phase != GamePhase.riverSqueeze) {
      return;
    }

    _squeezeProgress = progress.clamp(0, 1).toDouble();
    notifyListeners();
  }

  Future<void> completeRiverSqueeze(double progress) async {
    if (_phase != GamePhase.riverSqueeze) {
      return;
    }

    updateSqueezeProgress(progress);
    if (_squeezeProgress < squeezeCompletionThreshold) {
      _squeezeProgress = 0;
      notifyListeners();
      return;
    }

    final river = _hiddenRiverCard;
    if (river == null) {
      return;
    }

    _squeezeProgress = 1;
    _board = [..._board, river];
    _hiddenRiverCard = null;
    _phase = GamePhase.showdown;
    _clearEquity();
    _evaluateShowdown();
    notifyListeners();
  }

  void newHand() {
    if (!canStartNewHand) {
      return;
    }

    _resetHand();
    notifyListeners();
  }

  Future<void> _dealHoleCards() async {
    _deckService.reset();
    _board = [];
    _hiddenRiverCard = null;
    _squeezeProgress = 0;
    _players = _players
        .map(
          (player) => player.copyWith(
            holeCards: _deckService.drawMany(2),
            clearEquity: true,
            isWinner: false,
            winningCards: {},
          ),
        )
        .toList();
    _phase = GamePhase.preflopDealt;
    notifyListeners();
    await _refreshEquity();
  }

  Future<void> _dealFlop() async {
    _board = _deckService.drawMany(3);
    _phase = GamePhase.flopDealt;
    notifyListeners();
    await _refreshEquity();
  }

  Future<void> _dealTurn() async {
    _board = [..._board, _deckService.draw()];
    _phase = GamePhase.turnDealt;
    notifyListeners();
    await _refreshEquity();
  }

  void _prepareRiverSqueeze() {
    _hiddenRiverCard = _deckService.draw();
    _squeezeProgress = 0;
    _clearEquity();
    _phase = GamePhase.riverSqueeze;
    notifyListeners();
  }

  void _changePlayerCount(int delta) {
    if (!showPlayerCountControls) {
      return;
    }

    final nextCount = (_players.length + delta).clamp(2, 8).toInt();
    if (nextCount == _players.length) {
      return;
    }

    _settings = _settings.copyWith(playerCount: nextCount);
    _resetHand();
    unawaited(_persistSettings());
    notifyListeners();
  }

  void _resetHand() {
    _equityGeneration += 1;
    _deckService.reset();
    _board = [];
    _hiddenRiverCard = null;
    _squeezeProgress = 0;
    _phase = GamePhase.ready;
    _players = _playersFromSettings(_settings);
  }

  Future<void> _refreshEquity() async {
    final generation = ++_equityGeneration;
    _players = _players
        .map((player) => player.copyWith(clearEquity: true))
        .toList();
    _isCalculatingEquity = true;
    notifyListeners();

    final equities = await _equityService.calculate(
      holeCards: _players.map((player) => player.holeCards).toList(),
      board: _board,
      phase: _phase,
    );

    if (generation != _equityGeneration || !showEquity) {
      return;
    }

    _players = _players
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(equity: equities[entry.key]))
        .toList();
    _isCalculatingEquity = false;
    notifyListeners();
  }

  void _clearEquity() {
    _players = _players
        .map((player) => player.copyWith(clearEquity: true))
        .toList();
    _isCalculatingEquity = false;
  }

  void _evaluateShowdown() {
    final result = _handEvaluatorService.evaluate(
      holeCards: _players.map((player) => player.holeCards).toList(),
      board: _board,
    );

    _players = _players.asMap().entries.map((entry) {
      final index = entry.key;
      final player = entry.value;
      return player.copyWith(
        isWinner: result.winnerIndexes.contains(index),
        winningCards: result.winningCardsByPlayer[index] ?? {},
      );
    }).toList();
  }

  List<Player> _playersFromSettings(AppSettings settings) {
    return List.generate(
      settings.playerCount,
      (index) => Player(id: index, name: settings.nameFor(index)),
    );
  }

  Future<void> _persistSettings() {
    return _storageService.save(_settings);
  }

  String configuredPlayerName(int index) => _settings.nameFor(index);

  String _normalizePlayerName(int index, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Player ${index + 1}';
    }

    return trimmed.length <= 12 ? trimmed : trimmed.substring(0, 12);
  }
}
