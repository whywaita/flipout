import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../models/settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Card colors',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<CardColorMode>(
                  segments: const [
                    ButtonSegment(
                      value: CardColorMode.twoColor,
                      label: Text('2-color'),
                    ),
                    ButtonSegment(
                      value: CardColorMode.fourColor,
                      label: Text('4-color'),
                    ),
                  ],
                  selected: {controller.settings.colorMode},
                  onSelectionChanged: (selected) {
                    unawaited(controller.updateColorMode(selected.first));
                  },
                ),
                const SizedBox(height: 22),
                Text('Players', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (var index = 0; index < maxPlayers; index += 1) ...[
                  TextFormField(
                    key: ValueKey('player-name-$index'),
                    initialValue: controller.settings.playerNameAt(index),
                    maxLength: 12,
                    decoration: InputDecoration(
                      labelText: 'Player ${index + 1}',
                      counterText: '',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      unawaited(controller.updatePlayerName(index, value));
                    },
                  ),
                  if (index != maxPlayers - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
