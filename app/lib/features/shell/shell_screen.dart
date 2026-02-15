import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/routes.dart';
import '../../providers/game_service_provider.dart';
import '../../providers/games_provider.dart';

/// App shell. New game creates game, sets current, navigates to game. Phase 1: wired to resolve and persist.
class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Colonize This')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                final service = ref.read(gameServiceProvider);
                final game = service.createNewGame();
                ref.read(currentGameProvider.notifier).state = game;
                if (context.mounted) Navigator.pushNamed(context, Routes.game);
              },
              child: const Text('New game'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final service = ref.read(gameServiceProvider);
                final ids = service.listGameIds();
                if (ids.isEmpty || !context.mounted) return;
                final game = service.loadGame(ids.first);
                if (game != null && context.mounted) {
                  ref.read(currentGameProvider.notifier).state = game;
                  if (context.mounted) Navigator.pushNamed(context, Routes.game);
                }
              },
              child: const Text('Load last saved'),
            ),
          ],
        ),
      ),
    );
  }
}
