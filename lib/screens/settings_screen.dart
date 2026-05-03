import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../models/card_color_mode.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, game, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Players',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              for (var index = 0; index < 8; index += 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    key: Key('playerName$index'),
                    initialValue: game.configuredPlayerName(index),
                    maxLength: 12,
                    decoration: InputDecoration(
                      labelText: 'Player ${index + 1}',
                      counterText: '',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        unawaited(game.updatePlayerName(index, value)),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Card colors',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              SegmentedButton<CardColorMode>(
                segments: [
                  for (final mode in CardColorMode.values)
                    ButtonSegment<CardColorMode>(
                      value: mode,
                      label: Text(mode.label),
                    ),
                ],
                selected: {game.cardColorMode},
                onSelectionChanged: (selection) =>
                    unawaited(game.updateCardColorMode(selection.first)),
              ),
            ],
          ),
        );
      },
    );
  }
}
