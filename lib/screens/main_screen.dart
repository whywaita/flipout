import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../models/game_phase.dart';
import '../models/player.dart';
import '../models/playing_card.dart';
import '../screens/settings_screen.dart';
import '../theme/tokens.dart';
import '../widgets/playing_card_view.dart';
import '../widgets/river_squeeze_card.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, game, _) {
        final isSqueeze = game.phase == GamePhase.riverSqueeze;
        return Scaffold(
          backgroundColor: FlipoutColors.bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                FlipoutSpace.s4,
                FlipoutSpace.s3,
                FlipoutSpace.s4,
                FlipoutSpace.s4,
              ),
              child: Column(
                children: [
                  _Header(game: game),
                  const SizedBox(height: FlipoutSpace.s3),
                  _Board(game: game),
                  const SizedBox(height: FlipoutSpace.s3),
                  if (game.showPlayerCountControls) ...[
                    _PlayerCountControls(game: game),
                    const SizedBox(height: FlipoutSpace.s2),
                  ],
                  Expanded(
                    child: isSqueeze
                        ? _SqueezeStage(game: game)
                        : _PlayerList(game: game),
                  ),
                  const SizedBox(height: FlipoutSpace.s3),
                  _PrimaryAction(game: game),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: FlipoutType.xl,
                fontWeight: FlipoutType.cta,
                letterSpacing: -0.2,
                color: FlipoutColors.text,
              ),
              children: [
                TextSpan(text: 'Flip'),
                TextSpan(
                  text: '·',
                  style: TextStyle(color: FlipoutColors.accent),
                ),
                TextSpan(text: 'Out'),
              ],
            ),
          ),
        ),
        _PhaseChip(phase: game.phase),
        const SizedBox(width: FlipoutSpace.s2),
        _IconButtonShell(
          tooltip: 'Settings',
          icon: Icons.settings_outlined,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({required this.phase});

  final GamePhase phase;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(phase);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FlipoutSpace.s3,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(FlipoutRadius.pill),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: palette.led,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: FlipoutSpace.s1),
          Text(
            phase.label,
            style: TextStyle(
              color: palette.ink,
              fontSize: FlipoutType.xs,
              fontWeight: FlipoutType.cta,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  _ChipPalette _paletteFor(GamePhase phase) {
    switch (phase) {
      case GamePhase.riverSqueeze:
        return const _ChipPalette(
          bg: FlipoutColors.squeezeSoft,
          border: FlipoutColors.squeeze,
          led: FlipoutColors.squeeze,
          ink: FlipoutColors.squeezeInk,
        );
      case GamePhase.showdown:
        return const _ChipPalette(
          bg: FlipoutColors.winnerSoft,
          border: FlipoutColors.winner,
          led: FlipoutColors.winner,
          ink: FlipoutColors.winnerInk,
        );
      case GamePhase.ready:
      case GamePhase.preflopDealt:
      case GamePhase.flopDealt:
      case GamePhase.turnDealt:
        return const _ChipPalette(
          bg: FlipoutColors.accentSoft,
          border: FlipoutColors.accent,
          led: FlipoutColors.accent,
          ink: FlipoutColors.accentInk,
        );
    }
  }
}

class _ChipPalette {
  const _ChipPalette({
    required this.bg,
    required this.border,
    required this.led,
    required this.ink,
  });

  final Color bg;
  final Color border;
  final Color led;
  final Color ink;
}

class _IconButtonShell extends StatelessWidget {
  const _IconButtonShell({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Material(
          color: FlipoutColors.surface1,
          borderRadius: BorderRadius.circular(FlipoutRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(FlipoutRadius.md),
            onTap: onPressed,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(FlipoutRadius.md),
                border: Border.all(color: FlipoutColors.border),
              ),
              child: Icon(icon, size: 18, color: FlipoutColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    final winningBoardCards = game.players
        .where((player) => player.isWinner)
        .expand((player) => player.winningCards)
        .toSet();

    return Container(
      decoration: BoxDecoration(
        color: FlipoutColors.surface1,
        borderRadius: BorderRadius.circular(FlipoutRadius.lg),
        border: Border.all(color: FlipoutColors.border),
        boxShadow: FlipoutShadows.shadow1,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FlipoutSpace.s4,
          FlipoutSpace.s3,
          FlipoutSpace.s4,
          FlipoutSpace.s3,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BOARD',
                  style: TextStyle(
                    color: FlipoutColors.accentInk,
                    fontSize: FlipoutType.xs,
                    fontWeight: FlipoutType.cta,
                    letterSpacing: 1.4,
                  ),
                ),
                Text(
                  _boardMeta(game),
                  style: const TextStyle(
                    color: FlipoutColors.textDim,
                    fontSize: FlipoutType.xs,
                    fontWeight: FlipoutType.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FlipoutSpace.s2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < 5; index += 1) ...[
                  if (index > 0) const SizedBox(width: FlipoutSpace.s2),
                  _BoardSlot(
                    game: game,
                    index: index,
                    highlightCards: winningBoardCards,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _boardMeta(GameController game) {
    switch (game.phase) {
      case GamePhase.ready:
        return '— · — · —';
      case GamePhase.preflopDealt:
        return 'awaiting flop';
      case GamePhase.flopDealt:
        return '3 / 5';
      case GamePhase.turnDealt:
        return '4 / 5';
      case GamePhase.riverSqueeze:
        return 'river hidden';
      case GamePhase.showdown:
        return '5 / 5 · final';
    }
  }
}

class _BoardSlot extends StatelessWidget {
  const _BoardSlot({
    required this.game,
    required this.index,
    required this.highlightCards,
  });

  final GameController game;
  final int index;
  final Set<PlayingCard> highlightCards;

  @override
  Widget build(BuildContext context) {
    if (index < game.board.length) {
      final card = game.board[index];
      return PlayingCardView(
        card: card,
        colorMode: game.cardColorMode,
        highlight: highlightCards.contains(card),
      );
    }

    final riverCard = game.hiddenRiverCard;
    if (index == 4 && riverCard != null) {
      return PlayingCardView(
        card: null,
        colorMode: game.cardColorMode,
        faceDown: true,
      );
    }

    return const _EmptyCardSlot();
  }
}

class _EmptyCardSlot extends StatelessWidget {
  const _EmptyCardSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 78,
      decoration: BoxDecoration(
        color: FlipoutColors.surface2,
        borderRadius: BorderRadius.circular(FlipoutRadius.sm),
        border: Border.all(
          color: FlipoutColors.borderStrong,
          style: BorderStyle.solid,
        ),
      ),
    );
  }
}

class _PlayerCountControls extends StatelessWidget {
  const _PlayerCountControls({required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FlipoutSpace.s3,
        vertical: FlipoutSpace.s2,
      ),
      decoration: BoxDecoration(
        color: FlipoutColors.surface1,
        borderRadius: BorderRadius.circular(FlipoutRadius.md),
        border: Border.all(color: FlipoutColors.border),
        boxShadow: FlipoutShadows.shadow1,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'PLAYERS',
              style: TextStyle(
                color: FlipoutColors.accentInk,
                fontSize: FlipoutType.xs,
                fontWeight: FlipoutType.cta,
                letterSpacing: 1.4,
              ),
            ),
          ),
          _StepperButton(
            keyValue: const Key('decrementPlayers'),
            icon: Icons.remove,
            onPressed: game.players.length > 2 ? game.decrementPlayers : null,
          ),
          SizedBox(
            width: 36,
            child: Center(
              child: Text(
                '${game.players.length}',
                style: const TextStyle(
                  fontSize: FlipoutType.lg,
                  fontWeight: FlipoutType.cta,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          _StepperButton(
            keyValue: const Key('incrementPlayers'),
            icon: Icons.add,
            onPressed: game.players.length < 8 ? game.incrementPlayers : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.keyValue,
    required this.icon,
    required this.onPressed,
  });

  final Key keyValue;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return SizedBox(
      key: keyValue,
      width: 32,
      height: 32,
      child: Material(
        color: disabled ? FlipoutColors.surface2 : FlipoutColors.surface2,
        borderRadius: BorderRadius.circular(FlipoutRadius.md - 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(FlipoutRadius.md - 2),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FlipoutRadius.md - 2),
              border: Border.all(color: FlipoutColors.borderStrong),
            ),
            child: Opacity(
              opacity: disabled ? 0.35 : 1,
              child: Icon(icon, size: 18, color: FlipoutColors.text),
            ),
          ),
        ),
      ),
    );
  }
}

class _SqueezeStage extends StatelessWidget {
  const _SqueezeStage({required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    final riverCard = game.hiddenRiverCard;
    if (riverCard == null) return const SizedBox.shrink();
    return Center(
      child: SingleChildScrollView(
        child: RiverSqueezeCard(
          key: const Key('riverSqueeze'),
          card: riverCard,
          colorMode: game.cardColorMode,
          progress: game.squeezeProgress,
          onProgress: game.updateSqueezeProgress,
          onRelease: (progress) =>
              unawaited(game.completeRiverSqueeze(progress)),
        ),
      ),
    );
  }
}

class _PlayerList extends StatelessWidget {
  const _PlayerList({required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: game.players.length,
      separatorBuilder: (_, __) => const SizedBox(height: FlipoutSpace.s2),
      itemBuilder: (context, index) {
        return _PlayerRow(player: game.players[index], game: game);
      },
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.game});

  final Player player;
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final isWinner = player.isWinner;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(
        horizontal: FlipoutSpace.s3,
        vertical: FlipoutSpace.s2,
      ),
      decoration: BoxDecoration(
        color: isWinner ? FlipoutColors.winnerSoft : FlipoutColors.surface1,
        borderRadius: BorderRadius.circular(FlipoutRadius.md),
        border: Border.all(
          color: isWinner ? FlipoutColors.winner : FlipoutColors.border,
          width: isWinner ? 1.5 : 1,
        ),
        boxShadow: FlipoutShadows.shadow1,
      ),
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FlipoutType.bold,
                fontSize: FlipoutType.md,
                color: isWinner ? FlipoutColors.winnerInk : FlipoutColors.text,
              ),
            ),
          ),
          const SizedBox(width: FlipoutSpace.s2),
          for (final card in player.holeCards)
            Padding(
              padding: const EdgeInsets.only(right: FlipoutSpace.s1),
              child: PlayingCardView(
                card: card,
                colorMode: game.cardColorMode,
                compact: true,
                highlight: player.winningCards.contains(card),
              ),
            ),
          if (player.holeCards.isEmpty)
            const Padding(
              padding: EdgeInsets.only(right: FlipoutSpace.s1),
              child: Row(
                children: [
                  _EmptyHole(),
                  SizedBox(width: FlipoutSpace.s1),
                  _EmptyHole(),
                ],
              ),
            ),
          const Spacer(),
          if (game.phase == GamePhase.showdown)
            _ShowdownTrailing(player: player)
          else if (game.showEquity)
            _EquityBadge(player: player, game: game),
        ],
      ),
    );
  }
}

class _EmptyHole extends StatelessWidget {
  const _EmptyHole();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 56,
      decoration: BoxDecoration(
        color: FlipoutColors.surface2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: FlipoutColors.borderStrong),
      ),
    );
  }
}

class _ShowdownTrailing extends StatelessWidget {
  const _ShowdownTrailing({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (player.isWinner)
          const Text(
            'WIN',
            style: TextStyle(
              color: FlipoutColors.winner,
              fontSize: FlipoutType.md,
              fontWeight: FlipoutType.cta,
              letterSpacing: 1.2,
            ),
          ),
        if (player.handLabel != null)
          Text(
            player.handLabel!,
            style: TextStyle(
              color: player.isWinner
                  ? FlipoutColors.winner
                  : FlipoutColors.textDim,
              fontSize: FlipoutType.xs,
              fontWeight: FlipoutType.bold,
              letterSpacing: 0.4,
            ),
          ),
      ],
    );
  }
}

class _EquityBadge extends StatelessWidget {
  const _EquityBadge({required this.player, required this.game});

  final Player player;
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final equity = player.equity;
    final loading = game.isCalculatingEquity || equity == null;

    return SizedBox(
      width: 64,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: FlipoutColors.accent,
              ),
            )
          else ...[
            Text(
              '${(equity * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: FlipoutColors.accent,
                fontSize: FlipoutType.md,
                fontWeight: FlipoutType.cta,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  value: equity.clamp(0, 1).toDouble(),
                  backgroundColor: FlipoutColors.surface3,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    FlipoutColors.accent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    if (game.canStartNewHand) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          key: const Key('newHandButton'),
          onPressed: game.newHand,
          style: OutlinedButton.styleFrom(
            backgroundColor: FlipoutColors.surface1,
            foregroundColor: FlipoutColors.accentInk,
            side: const BorderSide(color: FlipoutColors.accent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FlipoutRadius.md),
            ),
          ),
          child: const Text(
            'NEW HAND',
            style: TextStyle(
              fontWeight: FlipoutType.cta,
              fontSize: FlipoutType.lg,
              letterSpacing: 2.2,
            ),
          ),
        ),
      );
    }

    final enabled = game.canDeal;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FlipoutRadius.md),
          gradient: enabled
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [FlipoutColors.accent, FlipoutColors.accentHover],
                )
              : null,
          color: enabled ? null : FlipoutColors.surface2,
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0x40134e4a),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Color(0x400d9488),
                    offset: Offset(0, 8),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('dealButton'),
            borderRadius: BorderRadius.circular(FlipoutRadius.md),
            onTap: enabled ? () => unawaited(game.deal()) : null,
            child: Center(
              child: Text(
                _dealLabel(game.phase),
                style: TextStyle(
                  fontWeight: FlipoutType.cta,
                  fontSize: FlipoutType.lg,
                  letterSpacing: 2.2,
                  color: enabled ? Colors.white : FlipoutColors.textDim,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _dealLabel(GamePhase phase) {
    switch (phase) {
      case GamePhase.ready:
        return 'DEAL';
      case GamePhase.preflopDealt:
        return 'DEAL FLOP';
      case GamePhase.flopDealt:
        return 'DEAL TURN';
      case GamePhase.turnDealt:
        return 'DEAL RIVER';
      case GamePhase.riverSqueeze:
        return 'DEAL';
      case GamePhase.showdown:
        return 'DEAL';
    }
  }
}
