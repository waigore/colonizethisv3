import 'package:colonizethis_logic/colonizethis_logic.dart';
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
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: ColonizeThisGame()),
          if (game != null)
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
        ],
      ),
    );
  }
}
