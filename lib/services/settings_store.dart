import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings.dart';

abstract interface class SettingsStore {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}

class SharedPreferencesSettingsStore implements SettingsStore {
  static const _playerNamesKey = 'player_names';
  static const _colorModeKey = 'card_color_mode';

  @override
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = AppSettings.defaults();
    final storedNames = prefs.getStringList(_playerNamesKey) ?? const [];
    final names = [
      for (var index = 0; index < maxPlayers; index += 1)
        if (index < storedNames.length && storedNames[index].trim().isNotEmpty)
          storedNames[index]
        else
          defaultPlayerName(index),
    ];

    final colorModeName = prefs.getString(_colorModeKey);
    final colorMode = CardColorMode.values
        .where((mode) => mode.name == colorModeName)
        .firstOrNull;

    return defaults.copyWith(
      playerNames: names,
      colorMode: colorMode ?? defaults.colorMode,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_playerNamesKey, _normalizedNames(settings));
    await prefs.setString(_colorModeKey, settings.colorMode.name);
  }

  List<String> _normalizedNames(AppSettings settings) {
    return [
      for (var index = 0; index < maxPlayers; index += 1)
        settings.playerNameAt(index),
    ];
  }
}

class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore({AppSettings? initial})
    : _settings = initial ?? AppSettings.defaults();

  AppSettings _settings;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
  }
}
