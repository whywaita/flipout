import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_color_mode.dart';
import '../models/settings.dart';

abstract class SettingsStorage {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

class SharedPreferencesSettingsStorage implements SettingsStorage {
  static const _playerCountKey = 'flipout.playerCount';
  static const _playerNamesKey = 'flipout.playerNames';
  static const _cardColorModeKey = 'flipout.cardColorMode';

  @override
  Future<AppSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final defaults = AppSettings.defaults();
    final storedNames = preferences.getStringList(_playerNamesKey);
    final names = List<String>.from(storedNames ?? defaults.playerNames);
    while (names.length < 8) {
      names.add('Player ${names.length + 1}');
    }

    return AppSettings(
      playerCount: (preferences.getInt(_playerCountKey) ?? defaults.playerCount)
          .clamp(2, 8)
          .toInt(),
      playerNames: names.take(8).toList(),
      cardColorMode: CardColorMode.fromName(
        preferences.getString(_cardColorModeKey),
      ),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt(_playerCountKey, settings.playerCount);
      await preferences.setStringList(_playerNamesKey, settings.playerNames);
      await preferences.setString(
        _cardColorModeKey,
        settings.cardColorMode.name,
      );
    } on Object {
      // LocalStorage may be unavailable in private or constrained contexts.
    }
  }
}

class MemoryStorageService implements SettingsStorage {
  AppSettings _settings = AppSettings.defaults();

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
  }
}
