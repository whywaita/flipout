import 'package:flutter/foundation.dart';

import '../models/game_stage.dart';
import '../models/player.dart';
import '../models/playing_card.dart';
import '../models/settings.dart';
import '../services/deck_service.dart';
import '../services/equity_service.dart';
import '../services/hand_evaluator_service.dart';
import '../services/settings_store.dart';

class GameController extends ChangeNotifier {
  GameController({
    DeckService? deckService,
    EquityService? equityService,
    SettingsStore? settingsStore,
    HandEvaluatorService? handEvaluatorService,
  }) : deckService = deckService ?? DeckService(),
       equityService = equityService ?? const PokerEquityService(),
       settingsStore = settingsStore ?? SharedPreferencesSettingsStore(),
       handEvaluatorService =
           handEvaluatorService ?? const HandEvaluatorService() {
    _players = _buildPlayers(minPlayers, _settings);
  }

  final DeckService deckService;
  final EquityService equityService;
  final SettingsStore settingsStore;
  final HandEvaluatorService handEvaluatorService;

  AppSettings _settings = AppSettings.defaults();
  late List<Player> _players;
  GameStage _stage = GameStage.ready;
  final List<PlayingCard> _board = [];
  PlayingCard? _pendingRiver;
  double _riverSqueezeProgress = 0;
  bool _isCalculatingEquity = false;
  int _calculationGeneration = 0;
  Set<int> _winningPlayerIndexes = {};
  Set<PlayingCard> _boardHighlights = {};

  AppSettings get settings => _settings;

  List<Player> get players => List.unmodifiable(_players);

  List<PlayingCard> get board => List.unmodifiable(_board);

  PlayingCard? get pendingRiver => _pendingRiver;

  GameStage get stage => _stage;

  double get riverSqueezeProgress => _riverSqueezeProgress;

  bool get isCalculatingEquity => _isCalculatingEquity;

  Set<int> get winningPlayerIndexes => Set.unmodifiable(_winningPlayerIndexes);

  Set<PlayingCard> get boardHighlights => Set.unmodifiable(_boardHighlights);

  bool get canDeal {
    return !_isCalculatingEquity &&
        switch (_stage) {
          GameStage.ready ||
          GameStage.preflopDealt ||
          GameStage.flopDealt ||
          GameStage.turnDealt => true,
          GameStage.riverSqueeze || GameStage.showdown => false,
        };
  }

  bool get canChangePlayerCount {
    return !_isCalculatingEquity && _stage == GameStage.preflopDealt;
  }

  bool get canNewHand => _stage == GameStage.showdown;

  Future<void> initialize() async {
    _settings = await settingsStore.load();
    _players = _buildPlayers(_players.length, _settings);
    notifyListeners();
  }

  Future<void> deal() async {
    if (!canDeal) {
      return;
    }

    switch (_stage) {
      case GameStage.ready:
        await _dealPreflop();
      case GameStage.preflopDealt:
        await _dealFlop();
      case GameStage.flopDealt:
        await _dealTurn();
      case GameStage.turnDealt:
        _prepareRiverSqueeze();
      case GameStage.riverSqueeze || GameStage.showdown:
        return;
    }
  }

  void setPlayerCount(int count) {
    if (!canChangePlayerCount) {
      return;
    }

    final normalized = count.clamp(minPlayers, maxPlayers);
    if (normalized == _players.length) {
      return;
    }

    _cancelEquityCalculation();
    _players = _buildPlayers(normalized, _settings);
    _resetHandState();
    notifyListeners();
  }

  void newHand() {
    if (!canNewHand) {
      return;
    }

    _cancelEquityCalculation();
    _players = [
      for (final player in _players)
        player.copyWith(
          holeCards: const [],
          clearEquity: true,
          isWinner: false,
          highlightedCards: const {},
        ),
    ];
    _resetHandState();
    notifyListeners();
  }

  void updateRiverSqueezeProgress(double progress) {
    if (_stage != GameStage.riverSqueeze) {
      return;
    }

    _riverSqueezeProgress = progress.clamp(0, 1);
    if (_riverSqueezeProgress >= 0.6) {
      _completeRiverSqueeze();
      return;
    }

    notifyListeners();
  }

  void releaseRiverSqueeze() {
    if (_stage != GameStage.riverSqueeze) {
      return;
    }

    if (_riverSqueezeProgress >= 0.6) {
      _completeRiverSqueeze();
      return;
    }

    _riverSqueezeProgress = 0;
    notifyListeners();
  }

  Future<void> updatePlayerName(int index, String value) async {
    if (index < 0 || index >= maxPlayers) {
      return;
    }

    final normalized = _normalizePlayerName(index, value);
    final names = [
      for (var i = 0; i < maxPlayers; i += 1)
        i == index ? normalized : _settings.playerNameAt(i),
    ];

    _settings = _settings.copyWith(playerNames: names);
    if (index < _players.length) {
      _players = [
        for (final player in _players)
          if (player.seatIndex == index)
            player.copyWith(name: normalized)
          else
            player,
      ];
    }

    await settingsStore.save(_settings);
    notifyListeners();
  }

  Future<void> updateColorMode(CardColorMode colorMode) async {
    _settings = _settings.copyWith(colorMode: colorMode);
    await settingsStore.save(_settings);
    notifyListeners();
  }

  Future<void> _dealPreflop() async {
    deckService.reset();
    _board.clear();
    _pendingRiver = null;
    _riverSqueezeProgress = 0;
    _winningPlayerIndexes = {};
    _boardHighlights = {};
    _players = [
      for (final player in _players)
        player.copyWith(
          holeCards: [deckService.draw(), deckService.draw()],
          clearEquity: true,
          isWinner: false,
          highlightedCards: const {},
        ),
    ];
    _stage = GameStage.preflopDealt;
    notifyListeners();
    await _calculateEquity(EquityMode.preflop);
  }

  Future<void> _dealFlop() async {
    _board.addAll([deckService.draw(), deckService.draw(), deckService.draw()]);
    _stage = GameStage.flopDealt;
    _clearPlayerEquity();
    notifyListeners();
    await _calculateEquity(EquityMode.flop);
  }

  Future<void> _dealTurn() async {
    _board.add(deckService.draw());
    _stage = GameStage.turnDealt;
    _clearPlayerEquity();
    notifyListeners();
    await _calculateEquity(EquityMode.turn);
  }

  void _prepareRiverSqueeze() {
    _pendingRiver = deckService.draw();
    _riverSqueezeProgress = 0;
    _stage = GameStage.riverSqueeze;
    _clearPlayerEquity();
    notifyListeners();
  }

  void _completeRiverSqueeze() {
    final river = _pendingRiver;
    if (river == null) {
      return;
    }

    _board.add(river);
    _pendingRiver = null;
    _riverSqueezeProgress = 1;
    _stage = GameStage.showdown;

    final result = handEvaluatorService.evaluate(
      holeCards: [for (final player in _players) player.holeCards],
      board: _board,
    );
    _winningPlayerIndexes = result.winningPlayerIndexes;
    _boardHighlights = result.boardHighlights;
    _players = [
      for (var index = 0; index < _players.length; index += 1)
        _players[index].copyWith(
          clearEquity: true,
          isWinner: _winningPlayerIndexes.contains(index),
          highlightedCards: result.players[index].bestFiveCards,
        ),
    ];

    notifyListeners();
  }

  Future<void> _calculateEquity(EquityMode mode) async {
    final generation = ++_calculationGeneration;
    _isCalculatingEquity = true;
    notifyListeners();

    List<double> equities;
    try {
      equities = await equityService.calculate(
        holeCards: [for (final player in _players) player.holeCards],
        communityCards: _board,
        mode: mode,
      );
    } catch (_) {
      equities = List<double>.filled(_players.length, 1 / _players.length);
    }

    if (generation != _calculationGeneration || !_stage.showsEquity) {
      return;
    }

    _players = [
      for (var index = 0; index < _players.length; index += 1)
        _players[index].copyWith(equity: equities[index]),
    ];
    _isCalculatingEquity = false;
    notifyListeners();
  }

  void _cancelEquityCalculation() {
    _calculationGeneration += 1;
    _isCalculatingEquity = false;
  }

  void _clearPlayerEquity() {
    _players = [
      for (final player in _players) player.copyWith(clearEquity: true),
    ];
  }

  void _resetHandState() {
    _stage = GameStage.ready;
    _board.clear();
    _pendingRiver = null;
    _riverSqueezeProgress = 0;
    _winningPlayerIndexes = {};
    _boardHighlights = {};
  }

  List<Player> _buildPlayers(int count, AppSettings settings) {
    return [
      for (var index = 0; index < count; index += 1)
        Player(seatIndex: index, name: settings.playerNameAt(index)),
    ];
  }

  String _normalizePlayerName(int index, String value) {
    final trimmed = value.trim();
    final fallback = defaultPlayerName(index);
    if (trimmed.isEmpty) {
      return fallback;
    }
    if (trimmed.length > 12) {
      return trimmed.substring(0, 12);
    }
    return trimmed;
  }
}
