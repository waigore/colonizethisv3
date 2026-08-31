// Session-cache reopen profiling anchors for empire-rail panels (Refs #4688 Slices 6–8).

import 'package:colonizethis_app/features/game/widgets/technology/technology_panel_open_path.dart';
import 'package:colonizethis_app/providers/counsel_panel_session_cache_provider.dart';
import 'package:colonizethis_app/providers/technology_panel_session_cache_provider.dart';
import 'package:colonizethis_app/providers/units_panel_session_cache_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'empire_rail_panel_open_path_timing_fixture.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  test(
    'cached civilian open path resolve is faster than cold build (Refs #4688 Slice 6)',
    () {
      const iterations = 20;
      final game = buildCivilianPanelTestGame();
      const ownerIds = {kPanelTestHumanPlayerId};
      const orders = Orders();

      final coldMicros = empireRailOpenPathTimeMicrosMedian(
        () => resolveCivilianUnitsPanelOpenPath(
          cache: UnitsPanelSessionCache(),
          game: game,
          ownerIds: ownerIds,
          currentOrders: orders,
          useSessionCache: false,
        ),
        iterations: iterations,
      );

      final cache = UnitsPanelSessionCache();
      resolveCivilianUnitsPanelOpenPath(
        cache: cache,
        game: game,
        ownerIds: ownerIds,
        currentOrders: orders,
        useSessionCache: true,
      );

      final warmMicros = empireRailOpenPathTimeMicrosMedian(
        () => resolveCivilianUnitsPanelOpenPath(
          cache: cache,
          game: game,
          ownerIds: ownerIds,
          currentOrders: orders,
          useSessionCache: true,
        ),
        iterations: iterations,
      );

      expect(warmMicros, lessThan(coldMicros));
      expect(
        (coldMicros - warmMicros) / coldMicros,
        greaterThanOrEqualTo(0.5),
        reason: 'cold=$coldMicrosµs warm=$warmMicrosµs',
      );
    },
  );

  test(
    'cached technology slots open path is faster than cold build (Refs #4688 Slice 7)',
    () {
      const iterations = 20;
      final game = buildTechnologyPanelTestGame();
      final player = game.players.first;
      const orders = Orders();
      final revision = technologyPanelSessionRevision(
        game: game,
        humanPlayerId: player.id,
        orders: orders,
        canEdit: true,
      );

      final coldMicros = empireRailOpenPathTimeMicrosMedian(
        () => resolveTechnologyPanelSlotsOpenPath(
          cache: TechnologyPanelSessionCache(),
          revision: revision,
          game: game,
          player: player,
          orders: orders,
        ),
        iterations: iterations,
      );

      final cache = TechnologyPanelSessionCache();
      resolveTechnologyPanelSlotsOpenPath(
        cache: cache,
        revision: revision,
        game: game,
        player: player,
        orders: orders,
      );

      final warmMicros = empireRailOpenPathTimeMicrosMedian(
        () => resolveTechnologyPanelSlotsOpenPath(
          cache: cache,
          revision: revision,
          game: game,
          player: player,
          orders: orders,
        ),
        iterations: iterations,
      );

      expect(warmMicros, lessThan(coldMicros));
      expect(
        (coldMicros - warmMicros) / coldMicros,
        greaterThanOrEqualTo(0.5),
        reason: 'cold=$coldMicrosµs warm=$warmMicrosµs',
      );
    },
  );

  test(
    'cached counsel industry resolve is faster than cold build (Refs #4688 Slice 8)',
    () {
      const iterations = 20;
      final game = buildMilitaryPanelTestGame();
      const topology = MapTopology();
      const orders = Orders();
      const desiredOutput = <String, int>{};
      final revision = counselPanelSessionRevision(
        game: game,
        orders: orders,
        desiredOutputByRecipe: desiredOutput,
        topology: topology,
      );

      final coldMicros = empireRailOpenPathTimeMicrosMedian(
        () => resolveCounselIndustryRecommendations(
          cache: CounselPanelSessionCache(),
          revision: revision,
          game: game,
          playerId: kPanelTestHumanPlayerId,
          currentOrders: orders,
          topology: topology,
          tileMapByRegion: const {},
        ),
        iterations: iterations,
      );

      final cache = CounselPanelSessionCache();
      resolveCounselIndustryRecommendations(
        cache: cache,
        revision: revision,
        game: game,
        playerId: kPanelTestHumanPlayerId,
        currentOrders: orders,
        topology: topology,
        tileMapByRegion: const {},
      );

      final warmMicros = empireRailOpenPathTimeMicrosMedian(
        () => resolveCounselIndustryRecommendations(
          cache: cache,
          revision: revision,
          game: game,
          playerId: kPanelTestHumanPlayerId,
          currentOrders: orders,
          topology: topology,
          tileMapByRegion: const {},
        ),
        iterations: iterations,
      );

      expect(warmMicros, lessThan(coldMicros));
      expect(
        (coldMicros - warmMicros) / coldMicros,
        greaterThanOrEqualTo(0.5),
        reason: 'cold=$coldMicrosµs warm=$warmMicrosµs',
      );
    },
  );
}
