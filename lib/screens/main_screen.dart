import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../models/player.dart';
import '../models/playing_card.dart';
import '../screens/settings_screen.dart';
import '../widgets/playing_card_view.dart';
import '../widgets/river_squeeze_card.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, game, _) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: [
                  _Header(game: game),
                  const SizedBox(height: 12),
                  _Board(game: game),
                  const SizedBox(height: 10),
                  if (game.showPlayerCountControls)
                    _PlayerCountControls(game: game),
                  if (game.showPlayerCountControls) const SizedBox(height: 8),
                  Expanded(child: _PlayerList(game: game)),
                  const SizedBox(height: 10),
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
        const Expanded(
          child: Text(
            'Flip-Out',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xff12352f),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xff2dd4bf)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Text(
              game.phase.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings),
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

class _Board extends StatelessWidget {
  const _Board({required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    final winningBoardCards = game.players
        .where((player) => player.isWinner)
        .expand((player) => player.winningCards)
        .toSet();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xff0f2f2a),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff1f4f46)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'BOARD',
                style: TextStyle(
                  color: Color(0xff99f6e4),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < 5; index += 1)
                  _BoardSlot(
                    game: game,
                    index: index,
                    highlightCards: winningBoardCards,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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
      return RiverSqueezeCard(
        card: riverCard,
        colorMode: game.cardColorMode,
        progress: game.squeezeProgress,
        onProgress: game.updateSqueezeProgress,
        onRelease: (progress) => unawaited(game.completeRiverSqueeze(progress)),
      );
    }

    return const _EmptyCardSlot();
  }
}

class _EmptyCardSlot extends StatelessWidget {
  const _EmptyCardSlot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 78,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xff133b35),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xff2f5c55)),
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
    return Row(
      children: [
        const Text(
          'PLAYERS',
          style: TextStyle(
            color: Color(0xff99f6e4),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          key: const Key('decrementPlayers'),
          tooltip: 'Remove player',
          onPressed: game.players.length > 2 ? game.decrementPlayers : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 36,
          child: Center(
            child: Text(
              '${game.players.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        IconButton.filledTonal(
          key: const Key('incrementPlayers'),
          tooltip: 'Add player',
          onPressed: game.players.length < 8 ? game.incrementPlayers : null,
          icon: const Icon(Icons.add),
        ),
      ],
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
      separatorBuilder: (_, __) => const SizedBox(height: 8),
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
    final rowColor = player.isWinner
        ? const Color(0xff4d3b10)
        : const Color(0xff17202a);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: player.isWinner
              ? const Color(0xffffc857)
              : const Color(0xff2d3748),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 6),
          for (final card in player.holeCards)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: PlayingCardView(
                card: card,
                colorMode: game.cardColorMode,
                compact: true,
                highlight: player.winningCards.contains(card),
              ),
            ),
          if (player.holeCards.isEmpty)
            const Text('No cards', style: TextStyle(color: Color(0xff94a3b8))),
          const Spacer(),
          if (game.showEquity) _EquityBadge(player: player, game: game),
        ],
      ),
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
    return SizedBox(
      width: 64,
      child: Align(
        alignment: Alignment.centerRight,
        child: game.isCalculatingEquity || equity == null
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                '${(equity * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Color(0xff99f6e4),
                  fontWeight: FontWeight.w900,
                ),
              ),
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
        height: 54,
        child: FilledButton(
          key: const Key('newHandButton'),
          onPressed: game.newHand,
          child: const Text(
            'NEW HAND',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        key: const Key('dealButton'),
        onPressed: game.canDeal ? () => unawaited(game.deal()) : null,
        child: const Text(
          'DEAL',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
