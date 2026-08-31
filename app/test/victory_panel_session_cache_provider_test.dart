// Session-cache reuse for Victory panel open path (Refs #4688 Slice 5).

import 'package:colonizethis_app/providers/victory_panel_session_cache_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  test(
    'resolveVictoryPanelOpenPath reuses session cache on same revision (Refs #4688 Slice 5)',
    () {
      final game = buildPanelTestGame(
        players: [panelTestHumanPlayer()],
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            ownerId: 'gp1',
          ),
        ],
      );
      final cache = VictoryPanelSessionCache();

      final snapshotFirst = resolveVictoryPanelOpenPath(
        cache: cache,
        game: game,
        tileMapByRegion: const <String, TileMapResult>{},
        topologyByRegion: const <String, MapTopology>{},
      );
      expect(snapshotFirst.standings, isNotEmpty);

      final snapshotSecond = resolveVictoryPanelOpenPath(
        cache: cache,
        game: game,
        tileMapByRegion: const <String, TileMapResult>{},
        topologyByRegion: const <String, MapTopology>{},
      );
      expect(identical(snapshotFirst, snapshotSecond), isTrue);
    },
  );

  test(
    'VictoryPanelSessionCache.reset drops cached snapshot (Refs #4688 Slice 5)',
    () {
      final game = buildPanelTestGame(players: [panelTestHumanPlayer()]);
      final cache = VictoryPanelSessionCache();

      resolveVictoryPanelOpenPath(
        cache: cache,
        game: game,
        tileMapByRegion: const <String, TileMapResult>{},
        topologyByRegion: const <String, MapTopology>{},
      );
      expect(cache.state.snapshot, isNotNull);

      cache.reset();
      expect(cache.state.snapshot, isNull);
      expect(cache.state.revision, isNull);
    },
  );
}
