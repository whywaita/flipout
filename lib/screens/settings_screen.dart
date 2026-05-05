import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../models/card_color_mode.dart';
import '../theme/tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, game, _) {
        return Scaffold(
          backgroundColor: FlipoutColors.bg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _NavBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      FlipoutSpace.s4,
                      FlipoutSpace.s2,
                      FlipoutSpace.s4,
                      FlipoutSpace.s5,
                    ),
                    children: [
                      const _SectionTitle('Players'),
                      const SizedBox(height: FlipoutSpace.s2),
                      for (var index = 0; index < 8; index += 1)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: FlipoutSpace.s3,
                          ),
                          child: _PlayerNameField(index: index, game: game),
                        ),
                      const SizedBox(height: FlipoutSpace.s4),
                      const _SectionTitle('Card colors'),
                      const SizedBox(height: FlipoutSpace.s2),
                      _ColorModeToggle(game: game),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FlipoutSpace.s4,
        FlipoutSpace.s3,
        FlipoutSpace.s4,
        FlipoutSpace.s2,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Material(
              color: FlipoutColors.surface1,
              borderRadius: BorderRadius.circular(FlipoutRadius.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(FlipoutRadius.md),
                onTap: () => Navigator.of(context).maybePop(),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(FlipoutRadius.md),
                    border: Border.all(color: FlipoutColors.border),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: FlipoutColors.text,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: FlipoutSpace.s3),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: FlipoutType.lg,
              fontWeight: FlipoutType.cta,
              color: FlipoutColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: FlipoutType.xs,
        fontWeight: FlipoutType.cta,
        letterSpacing: 1.6,
        color: FlipoutColors.accentInk,
      ),
    );
  }
}

class _PlayerNameField extends StatelessWidget {
  const _PlayerNameField({required this.index, required this.game});

  final int index;
  final GameController game;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: Key('playerName$index'),
      initialValue: game.configuredPlayerName(index),
      maxLength: 12,
      style: const TextStyle(
        fontSize: FlipoutType.md,
        fontWeight: FlipoutType.bold,
        color: FlipoutColors.text,
      ),
      decoration: InputDecoration(
        labelText: 'Player ${index + 1}',
        labelStyle: const TextStyle(
          color: FlipoutColors.textMuted,
          fontWeight: FlipoutType.bold,
          fontSize: FlipoutType.sm,
          letterSpacing: 0.8,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        counterText: '',
        filled: true,
        fillColor: FlipoutColors.surface1,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FlipoutSpace.s3,
          vertical: FlipoutSpace.s3,
        ),
        border: _border(FlipoutColors.border),
        enabledBorder: _border(FlipoutColors.border),
        focusedBorder: _border(FlipoutColors.accent, width: 1.5),
      ),
      onChanged: (value) => unawaited(game.updatePlayerName(index, value)),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(FlipoutRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _ColorModeToggle extends StatelessWidget {
  const _ColorModeToggle({required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FlipoutColors.surface1,
        borderRadius: BorderRadius.circular(FlipoutRadius.md),
        border: Border.all(color: FlipoutColors.border),
        boxShadow: FlipoutShadows.shadow1,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FlipoutRadius.md),
        child: Row(
          children: [
            for (final mode in CardColorMode.values)
              Expanded(
                child: _ColorModeOption(
                  mode: mode,
                  selected: game.cardColorMode == mode,
                  onTap: () => unawaited(game.updateCardColorMode(mode)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ColorModeOption extends StatelessWidget {
  const _ColorModeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final CardColorMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? FlipoutColors.accent : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              mode.label,
              style: TextStyle(
                color: selected ? Colors.white : FlipoutColors.textMuted,
                fontSize: FlipoutType.md,
                fontWeight: selected ? FlipoutType.cta : FlipoutType.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
