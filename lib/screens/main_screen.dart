import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../models/game_state.dart';
import '../widgets/playing_card.dart';
import '../widgets/river_squeeze.dart';
import 'settings_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      appBar: AppBar(
        title: const Text('Flip-Out'),
        backgroundColor: const Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<GameController>(
        builder: (context, controller, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Board area
                  _buildBoardArea(controller),
                  const SizedBox(height: 24),

                  // Players list
                  Expanded(
                    child: _buildPlayersList(controller),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  _buildActionButtons(context, controller),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBoardArea(GameController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'BOARD',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              // Community cards
              ...controller.communityCards.map((card) {
                final isHighlighted = controller.state == GameState.showdown &&
                    controller.players.any((p) =>
                        p.isWinner && p.winningHand?.contains(card) == true);
                return PlayingCard(
                  card: card,
                  colorMode: controller.settings.cardColorMode,
                  isHighlighted: isHighlighted,
                );
              }),
              // River squeeze
              if (controller.state == GameState.riverSqueeze &&
                  controller.riverCard != null)
                RiverSqueeze(
                  riverCard: controller.riverCard!,
                  colorMode: controller.settings.cardColorMode,
                  onSqueezeComplete: () {
                    controller.completeRiverSqueeze();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList(GameController controller) {
    return ListView.builder(
      itemCount: controller.players.length,
      itemBuilder: (context, index) {
        final player = controller.players[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: player.isWinner
                ? Colors.amber.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: player.isWinner
                ? Border.all(color: Colors.amber, width: 2)
                : null,
          ),
          child: Row(
            children: [
              // Player name
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (player.equity != null)
                      Text(
                        '${player.equity!.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.green.shade300,
                          fontSize: 14,
                        ),
                      ),
                    if (controller.isCalculatingEquity)
                      Text(
                        'Calculating...',
                        style: TextStyle(
                          color: Colors.yellow.shade300,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Hole cards
              Expanded(
                flex: 3,
                child: Wrap(
                  spacing: 8,
                  children: player.holeCards.map((card) {
                    final isHighlighted = player.isWinner &&
                        player.winningHand?.contains(card) == true;
                    return PlayingCard(
                      card: card,
                      colorMode: controller.settings.cardColorMode,
                      width: 50,
                      height: 70,
                      isHighlighted: isHighlighted,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, GameController controller) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: controller.state == GameState.riverSqueeze
                ? null
                : () => controller.onDeal(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            child: const Text('DEAL'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => controller.newHand(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            child: const Text('NEW HAND'),
          ),
        ),
      ],
    );
  }
}
