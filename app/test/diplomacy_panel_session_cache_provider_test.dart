// Session-cache reuse for Diplomacy panel rows (Refs #4688 Slice 5).

import 'package:colonizethis_app/providers/diplomacy_panel_session_cache_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  test(
    'resolveDiplomacyPanelRows reuses session cache on same revision (Refs #4688 Slice 5)',
    () {
      final game = buildDiplomacyRichPanelTestGame();
      const topology = MapTopology();
      final humanPlayerId = game.players.first.id;
      const orders = Orders();
      final cache = DiplomacyPanelSessionCache();

      final rowsFirst = resolveDiplomacyPanelRows(
        cache: cache,
        game: game,
        topology: topology,
        humanPlayerId: humanPlayerId,
        orders: orders,
      );
      expect(rowsFirst, isNotEmpty);

      final rowsSecond = resolveDiplomacyPanelRows(
        cache: cache,
        game: game,
        topology: topology,
        humanPlayerId: humanPlayerId,
        orders: orders,
      );
      expect(identical(rowsFirst, rowsSecond), isTrue);
    },
  );

  test(
    'DiplomacyPanelSessionCache.reset drops cached rows (Refs #4688 Slice 5)',
    () {
      final game = buildDiplomacyRichPanelTestGame();
      const topology = MapTopology();
      final cache = DiplomacyPanelSessionCache();

      resolveDiplomacyPanelRows(
        cache: cache,
        game: game,
        topology: topology,
        humanPlayerId: game.players.first.id,
        orders: const Orders(),
      );
      expect(cache.state.rows, isNotNull);

      cache.reset();
      expect(cache.state.rows, isNull);
      expect(cache.state.revision, isNull);
    },
  );
}
