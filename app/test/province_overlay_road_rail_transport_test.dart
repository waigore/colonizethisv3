// Issue #1537 — Tile section shows numeric road/rail transport level + supplementary GDD labels.

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart';
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

void main() {
  suppressLogsForTests();

  group('road/rail transport Tile copy (issue #1537)', () {
    test('AC: sea / no land transport — single em dash line', () {
      expect(roadRailTileDetailLinesForTests(transportLevel: null), [
        'Road / railroad: —',
      ]);
    });

    test('AC: land level 0 — numeric 0 and supplementary none', () {
      expect(roadRailTileDetailLinesForTests(transportLevel: 0), [
        'Road / railroad: transport level 0',
        'none',
      ]);
    });

    test('AC: land level 1 — numeric 1, primitive road, rail gloss', () {
      expect(roadRailTileDetailLinesForTests(transportLevel: 1), [
        'Road / railroad: transport level 1',
        'primitive road',
        kRoadRailPrimitiveVersusRailGloss,
      ]);
    });

    test('AC: land level 2 — numeric 2 and improved road', () {
      expect(roadRailTileDetailLinesForTests(transportLevel: 2), [
        'Road / railroad: transport level 2',
        'improved road',
      ]);
    });

    test('AC: land level 4 — numeric 4 and port or railroad', () {
      expect(roadRailTileDetailLinesForTests(transportLevel: 4), [
        'Road / railroad: transport level 4',
        'port or railroad',
      ]);
    });

    test(
      'AC: unexpected positive level — numeric shown and non-standard label',
      () {
        expect(roadRailTileDetailLinesForTests(transportLevel: 3), [
          'Road / railroad: transport level 3',
          'non-standard transport level',
        ]);
      },
    );
  });

  group('ProvinceSeaZoneDetailOverlay Tile road/rail wiring', () {
    testWidgets(
      'AC: overlay shows transport level and supplementary label from game state',
      (WidgetTester tester) async {
        final base = demoGameForOverlay;
        final region = demoRegionForOverlay;
        final tileKey = sampleTileKeyForProvinceOverlay;
        final humanPlayerId = base.players.first.id;
        final init = getDebugInitGameResult();
        final playerView = buildPlayerView(
          base,
          init.combinedTopology,
          humanPlayerId,
        );

        final ws = base.worldState;
        final tileState = ws.tileState.setRoadLevel(tileKey, 2);
        final game = base.copyWith(
          worldState: ws.copyWith(tileState: tileState),
        );

        final parts = tileKey.split('|');
        expect(parts.length, greaterThanOrEqualTo(4));
        final provinceId = '${parts[0]}|${parts[1]}';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProvinceSeaZoneDetailOverlay(
                game: game,
                region: region,
                displayId: provinceId,
                selectedTileKey: tileKey,
                humanPlayerId: humanPlayerId,
                playerView: playerView,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Road / railroad: transport level 2'), findsOneWidget);
        expect(find.text('improved road'), findsOneWidget);
      },
    );
  });
}
