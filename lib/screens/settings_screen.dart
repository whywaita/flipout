import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../models/settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Settings _tempSettings;
  final List<TextEditingController> _nameControllers = [];

  @override
  void initState() {
    super.initState();
    final controller = context.read<GameController>();
    _tempSettings = controller.settings.copyWith(
      playerNames: List.from(controller.settings.playerNames),
    );
    _initializeControllers();
  }

  @override
  void dispose() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    _nameControllers.clear();
    for (int i = 0; i < _tempSettings.playerCount; i++) {
      final name = i < _tempSettings.playerNames.length
          ? _tempSettings.playerNames[i]
          : 'Player ${i + 1}';
      _nameControllers.add(TextEditingController(text: name));
    }
  }

  void _updatePlayerCount(int newCount) {
    setState(() {
      _tempSettings = _tempSettings.copyWith(playerCount: newCount);

      // Update name controllers
      while (_nameControllers.length < newCount) {
        _nameControllers.add(
          TextEditingController(text: 'Player ${_nameControllers.length + 1}'),
        );
      }
      while (_nameControllers.length > newCount) {
        _nameControllers.removeLast().dispose();
      }

      // Update player names list
      final names = <String>[];
      for (int i = 0; i < newCount; i++) {
        if (i < _nameControllers.length) {
          names.add(_nameControllers[i].text);
        } else {
          names.add('Player ${i + 1}');
        }
      }
      _tempSettings = _tempSettings.copyWith(playerNames: names);
    });
  }

  void _saveSettings() {
    // Update player names from controllers
    final names = _nameControllers.map((c) => c.text.trim()).toList();
    _tempSettings = _tempSettings.copyWith(playerNames: names);

    final controller = context.read<GameController>();
    controller.updateSettings(_tempSettings);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Player count
                  _buildSection(
                    title: 'Player Count',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.white),
                          onPressed: _tempSettings.playerCount > 2
                              ? () => _updatePlayerCount(
                                  _tempSettings.playerCount - 1)
                              : null,
                        ),
                        Text(
                          '${_tempSettings.playerCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.add_circle, color: Colors.white),
                          onPressed: _tempSettings.playerCount < 8
                              ? () => _updatePlayerCount(
                                  _tempSettings.playerCount + 1)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Player names
                  _buildSection(
                    title: 'Player Names',
                    child: Column(
                      children: List.generate(
                        _tempSettings.playerCount,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                            controller: _nameControllers[index],
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Player ${index + 1}',
                              labelStyle:
                                  const TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.white38),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Card color mode
                  _buildSection(
                    title: 'Card Color Mode',
                    child: Column(
                      children: [
                        RadioListTile<CardColorMode>(
                          title: const Text(
                            '4-Color',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Spades: Black, Hearts: Red, Diamonds: Blue, Clubs: Green',
                            style:
                                TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                          value: CardColorMode.fourColor,
                          groupValue: _tempSettings.cardColorMode,
                          onChanged: (value) {
                            setState(() {
                              _tempSettings = _tempSettings.copyWith(
                                cardColorMode: value,
                              );
                            });
                          },
                        ),
                        RadioListTile<CardColorMode>(
                          title: const Text(
                            '2-Color',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Spades & Clubs: Black, Hearts & Diamonds: Red',
                            style:
                                TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                          value: CardColorMode.twoColor,
                          groupValue: _tempSettings.cardColorMode,
                          onChanged: (value) {
                            setState(() {
                              _tempSettings = _tempSettings.copyWith(
                                cardColorMode: value,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('SAVE'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
