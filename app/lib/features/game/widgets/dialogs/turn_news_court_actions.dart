// Reveal OVL70001 from DLG50001 court tap. SPEC/ui/turn-news-dialog.md.

import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Same persist path as the newspaper toggle: `mapViewState.showPlayerTurnEventsFeed`.
void revealPlayerTurnEventsFeed(ProviderContainer container) {
  final current = container.read(currentGameProvider);
  if (current == null) return;
  if (current.mapViewState.showPlayerTurnEventsFeed) return;
  container
      .read(currentGameProvider.notifier)
      .setGame(
        current.copyWith(
          mapViewState: current.mapViewState.copyWith(
            showPlayerTurnEventsFeed: true,
          ),
        ),
      );
}
