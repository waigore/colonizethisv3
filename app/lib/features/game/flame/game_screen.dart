import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import 'game_canvas.dart';

/// Hosts the Flame game canvas. Phase 1: Next turn invokes TurnResolver and persists.
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(currentGameProvider);
    final victory = game?.victory;
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: ColonizeThisGame()),
          if (game != null && victory == null)
            Positioned(
              right: 16,
              top: 16,
              child: ElevatedButton(
                onPressed: () {
                  final service = ref.read(gameServiceProvider);
                  // Phase 2: orders and topology are not yet surfaced in the UI,
                  // so we pass empty orders and a default topology. This still
                  // exercises the full Phase 2 turn resolver pipeline.
                  final newGame = service.nextTurn(game);
                  ref.read(currentGameProvider.notifier).state = newGame;
                },
                child: Text(
                  'Next turn (${game.worldState.turnState.turnNumber} / ${turnToYear(game.worldState.turnState.turnNumber, game.turnTimeMapping)})',
                ),
              ),
            ),
          if (game != null && victory != null)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: _VictoryPanel(
                    game: game,
                    victory: victory,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VictoryPanel extends StatelessWidget {
  const _VictoryPanel({
    required this.game,
    required this.victory,
  });

  final ct_models.Game game;
  final ct_models.VictoryState victory;

  @override
  Widget build(BuildContext context) {
    final winner = game.players.firstWhere(
      (p) => p.id == victory.winnerPlayerId,
      orElse: () => game.players.first,
    );
    final victoryLabel = switch (victory.type) {
      ct_models.VictoryType.military => 'Military victory',
    };

    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              victoryLabel,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              '${winner.displayName} wins on turn ${victory.turnNumber}.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Return to main menu'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    // Simply close the panel; map remains visible but game is finished.
                    Navigator.of(context).maybePop();
                  },
                  child: const Text('View final state'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
