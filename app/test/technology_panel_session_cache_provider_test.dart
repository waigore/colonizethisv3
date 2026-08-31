// Session-cache reuse for Technology panel Slots-tab open path (Refs #4688 Slice 7).

import 'package:colonizethis_app/features/game/widgets/technology/technology_panel_open_path.dart';
import 'package:colonizethis_app/providers/technology_panel_session_cache_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  test(
    'resolveTechnologyPanelSlotsOpenPath reuses session cache on same revision (Refs #4688 Slice 7)',
    () {
      final game = buildTechnologyPanelTestGame();
      final player = game.players.first;
      const orders = Orders();
      final cache = TechnologyPanelSessionCache();
      final revision = technologyPanelSessionRevision(
        game: game,
        humanPlayerId: player.id,
        orders: orders,
        canEdit: true,
      );

      final first = resolveTechnologyPanelSlotsOpenPath(
        cache: cache,
        revision: revision,
        game: game,
        player: player,
        orders: orders,
      );
      final second = resolveTechnologyPanelSlotsOpenPath(
        cache: cache,
        revision: revision,
        game: game,
        player: player,
        orders: orders,
      );
      expect(identical(first, second), isTrue);
    },
  );

  test(
    'resolveTechnologyPanelSlotsOpenPath rebuilds when turn advances (Refs #4688 Slice 7)',
    () {
      final game = buildTechnologyPanelTestGame();
      final player = game.players.first;
      const orders = Orders();
      final cache = TechnologyPanelSessionCache();
      final revisionTurn1 = technologyPanelSessionRevision(
        game: game,
        humanPlayerId: player.id,
        orders: orders,
        canEdit: true,
      );

      final turn1 = resolveTechnologyPanelSlotsOpenPath(
        cache: cache,
        revision: revisionTurn1,
        game: game,
        player: player,
        orders: orders,
      );

      final advancedGame = game.copyWith(
        worldState: game.worldState.copyWith(
          turnState: game.worldState.turnState.copyWith(turnNumber: 2),
        ),
      );
      final revisionTurn2 = technologyPanelSessionRevision(
        game: advancedGame,
        humanPlayerId: player.id,
        orders: orders,
        canEdit: true,
      );
      final turn2 = resolveTechnologyPanelSlotsOpenPath(
        cache: cache,
        revision: revisionTurn2,
        game: advancedGame,
        player: player,
        orders: orders,
      );

      expect(identical(turn1, turn2), isFalse);
    },
  );

  test(
    'TechnologyPanelSessionCache.reset drops cached snapshot (Refs #4688 Slice 7)',
    () {
      final game = buildTechnologyPanelTestGame();
      final player = game.players.first;
      const orders = Orders();
      final cache = TechnologyPanelSessionCache();
      final revision = technologyPanelSessionRevision(
        game: game,
        humanPlayerId: player.id,
        orders: orders,
        canEdit: true,
      );

      resolveTechnologyPanelSlotsOpenPath(
        cache: cache,
        revision: revision,
        game: game,
        player: player,
        orders: orders,
      );
      expect(cache.state.snapshot, isNotNull);

      cache.reset();
      expect(cache.state.snapshot, isNull);
      expect(cache.state.revision, isNull);
    },
  );

  test(
    'technologyPanelSessionCacheProvider resets on clearActiveGameSession (Refs #4688 Slice 7)',
    () {
      final game = buildTechnologyPanelTestGame();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cache = container.read(technologyPanelSessionCacheProvider);
      final revision = technologyPanelSessionRevision(
        game: game,
        humanPlayerId: game.players.first.id,
        orders: const Orders(),
        canEdit: true,
      );
      resolveTechnologyPanelSlotsOpenPath(
        cache: cache,
        revision: revision,
        game: game,
        player: game.players.first,
        orders: const Orders(),
      );
      expect(cache.state.snapshot, isNotNull);

      cache.reset();
      expect(cache.state.snapshot, isNull);
    },
  );
}
