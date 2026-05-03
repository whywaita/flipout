import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../models/game_stage.dart';
import '../models/player.dart';
import '../models/settings.dart';
import '../screens/settings_screen.dart';
import '../widgets/playing_card_view.dart';
import '../widgets/river_squeeze_card.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Flip-Out'),
            actions: [
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.tune),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  _TableHeader(controller: controller),
                  const SizedBox(height: 10),
                  _Board(controller: controller),
                  const SizedBox(height: 10),
                  _PlayerCountBar(controller: controller),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      physics: const ClampingScrollPhysics(),
                      itemCount: controller.players.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        return _PlayerRow(
                          player: controller.players[index],
                          colorMode: controller.settings.colorMode,
                          showEquity: controller.stage.showsEquity,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PrimaryAction(controller: controller),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF123B2B),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              controller.stage.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const Spacer(),
        if (controller.isCalculatingEquity)
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0D5C3B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF083A28), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            for (var index = 0; index < 5; index += 1) ...[
              Expanded(child: _boardSlot(index)),
              if (index != 4) const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _boardSlot(int index) {
    if (index < controller.board.length) {
      final card = controller.board[index];
      return PlayingCardView(
        card: card,
        colorMode: controller.settings.colorMode,
        highlighted: controller.boardHighlights.contains(card),
      );
    }

    if (index == 4 && controller.pendingRiver != null) {
      return RiverSqueezeCard(
        card: controller.pendingRiver!,
        progress: controller.riverSqueezeProgress,
        onProgress: controller.updateRiverSqueezeProgress,
        onRelease: controller.releaseRiverSqueeze,
      );
    }

    return const PlayingCardView.empty();
  }
}

class _PlayerCountBar extends StatelessWidget {
  const _PlayerCountBar({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.stage != GameStage.preflopDealt) {
      return const SizedBox(height: 40);
    }

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Remove player',
            onPressed: controller.canChangePlayerCount
                ? () => controller.setPlayerCount(controller.players.length - 1)
                : null,
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${controller.players.length} players',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Add player',
            onPressed: controller.canChangePlayerCount
                ? () => controller.setPlayerCount(controller.players.length + 1)
                : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.colorMode,
    required this.showEquity,
  });

  final Player player;
  final CardColorMode colorMode;
  final bool showEquity;

  @override
  Widget build(BuildContext context) {
    final highlight = player.isWinner;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFFF0B8) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? const Color(0xFFB8872A) : const Color(0xFFD6D0C5),
          width: highlight ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(
              width: 86,
              child: Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            for (var index = 0; index < 2; index += 1) ...[
              SizedBox(
                width: 42,
                child: player.holeCards.length > index
                    ? PlayingCardView(
                        card: player.holeCards[index],
                        colorMode: colorMode,
                        compact: true,
                        highlighted: player.highlightedCards.contains(
                          player.holeCards[index],
                        ),
                      )
                    : const PlayingCardView.empty(compact: true),
              ),
              if (index == 0) const SizedBox(width: 4),
            ],
            const Spacer(),
            SizedBox(
              width: 62,
              child: _EquityText(player: player, showEquity: showEquity),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquityText extends StatelessWidget {
  const _EquityText({required this.player, required this.showEquity});

  final Player player;
  final bool showEquity;

  @override
  Widget build(BuildContext context) {
    if (!showEquity) {
      return const SizedBox.shrink();
    }

    final equity = player.equity;
    if (equity == null) {
      return const Align(
        alignment: Alignment.centerRight,
        child: SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Text(
      '${(equity * 100).toStringAsFixed(1)}%',
      textAlign: TextAlign.right,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final isShowdown = controller.stage == GameStage.showdown;
    final label = isShowdown
        ? 'NEW HAND'
        : controller.stage == GameStage.riverSqueeze
        ? 'SQUEEZE'
        : 'DEAL';

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: isShowdown
            ? controller.newHand
            : controller.canDeal
            ? () => unawaited(controller.deal())
            : null,
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
