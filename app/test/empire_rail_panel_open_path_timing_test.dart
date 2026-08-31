// Session-cache reopen profiling anchors for UNIT* panels (Refs #4688 Slice 4).
//
// CI surrogate for profile/release DevTools sessions: documents that cached
// military/naval tree resolve is measurably cheaper than a cold build on the
// panel test fixture. Not a debug wall-clock 1s assertion.

import 'package:colonizethis_app/providers/diplomacy_panel_session_cache_provider.dart';
import 'package:colonizethis_app/providers/units_panel_session_cache_provider.dart';
import 'package:colonizethis_app/providers/victory_panel_session_cache_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'empire_rail_panel_open_path_timing_fixture.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  test(
    'cached military tree resolve is faster than cold build (Refs #4688 Slice 4)',
    () {
      const iterations = 20;
      final game = buildMilitaryPanelTestGame();
      final coldMicros = empireRailOpenPathTimeMicrosMedian(
        () => resolveUnitsPanelMilitaryGroups(
          cache: UnitsPanelSessionCache(),
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
        ),
        iterations: iterations,
      );

      final cache = UnitsPanelSessionCache();
      resolveUnitsPanelMilitaryGroups(
        cache: cache,
        game: game,
        humanPlayerId: kPanelTestHumanPlayerId,
      );

      final warmMicros = empireRailOpenPathTimeMicrosMedian(
        () => resolveUnitsPanelMilitaryGroups(
          cache: cache,
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
        ),
        iterations: iterations,
      );

      final improvementRatio = (coldMicros - warmMicros) / coldMicros;
      expect(
        warmMicros,
        lessThan(coldMicros),
        reason:
            'cold=$coldMicrosµs warm=$warmMicrosµs '
            '(${ (improvementRatio * 100).toStringAsFixed(1)}% faster) '
            'over $iterations iterations',
      );
      expect(
        improvementRatio,
        greaterThanOrEqualTo(0.5),
        reason:
            'expected at least 50% military tree cache win; '
            'cold=$coldMicrosµs warm=$warmMicrosµs',
      );
    },
  );

  test(
    'cached naval tree resolve is faster than cold build (Refs #4688 Slice 4)',
    () {
      const iterations = 20;
      final game = buildNavalPanelTestGame();
      final l10n = lookupAppLocalizations(const Locale('en'));
      final coldMicros = empireRailOpenPathTimeMicrosMedian(
        () => resolveUnitsPanelNavalTree(
          cache: UnitsPanelSessionCache(),
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
          topology: const MapTopology(),
          draftOrders: const Orders(),
          l10n: l10n,
        ),
        iterations: iterations,
      );

      final cache = UnitsPanelSessionCache();
      resolveUnitsPanelNavalTree(
        cache: cache,
        game: game,
        humanPlayerId: kPanelTestHumanPlayerId,
        topology: const MapTopology(),
        draftOrders: const Orders(),
        l10n: l10n,
      );

      final warmMicros = empireRailOpenPathTimeMicrosMedian(
        () => resolveUnitsPanelNavalTree(
          cache: cache,
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
          topology: const MapTopology(),
          draftOrders: const Orders(),
          l10n: l10n,
        ),
        iterations: iterations,
      );

      final improvementRatio = (coldMicros - warmMicros) / coldMicros;
      expect(
        warmMicros,
        lessThan(coldMicros),
        reason:
            'cold=$coldMicrosµs warm=$warmMicrosµs '
            '(${ (improvementRatio * 100).toStringAsFixed(1)}% faster) '
            'over $iterations iterations',
      );
      expect(
        improvementRatio,
        greaterThanOrEqualTo(0.5),
        reason:
            'expected at least 50% naval tree cache win; '
            'cold=$coldMicrosµs warm=$warmMicrosµs',
      );
    },
  );

  test(
    'cached diplomacy rows resolve is faster than cold build (Refs #4688 Slice 5)',
    () {
      const iterations = 20;
      final game = buildMilitaryPanelTestGame();
      const topology = MapTopology();
      const orders = Orders();
      const humanPlayerId = kPanelTestHumanPlayerId;

      final coldMicros = empireRailOpenPathTimeMicrosMedian(
        () => resolveDiplomacyPanelRows(
          cache: DiplomacyPanelSessionCache(),
          game: game,
          topology: topology,
          humanPlayerId: humanPlayerId,
          orders: orders,
        ),
        iterations: iterations,
      );

      final cache = DiplomacyPanelSessionCache();
      resolveDiplomacyPanelRows(
        cache: cache,
        game: game,
        topology: topology,
        humanPlayerId: humanPlayerId,
        orders: orders,
      );

      final warmMicros = empireRailOpenPathTimeMicrosMedian(
        () => resolveDiplomacyPanelRows(
          cache: cache,
          game: game,
          topology: topology,
          humanPlayerId: humanPlayerId,
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
    'cached victory open path resolve is faster than cold build (Refs #4688 Slice 5)',
    () {
      const iterations = 20;
      final game = buildMilitaryPanelTestGame();

      final coldMicros = empireRailOpenPathTimeMicrosMedian(
        () => resolveVictoryPanelOpenPath(
          cache: VictoryPanelSessionCache(),
          game: game,
          tileMapByRegion: const <String, TileMapResult>{},
          topologyByRegion: const <String, MapTopology>{},
        ),
        iterations: iterations,
      );

      final cache = VictoryPanelSessionCache();
      resolveVictoryPanelOpenPath(
        cache: cache,
        game: game,
        tileMapByRegion: const <String, TileMapResult>{},
        topologyByRegion: const <String, MapTopology>{},
      );

      final warmMicros = empireRailOpenPathTimeMicrosMedian(
        () => resolveVictoryPanelOpenPath(
          cache: cache,
          game: game,
          tileMapByRegion: const <String, TileMapResult>{},
          topologyByRegion: const <String, MapTopology>{},
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
