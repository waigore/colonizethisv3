// Tests for ProvinceSeaZoneDetailOverlay tile selection and branching paths.
// Covers SPEC/ui/province-sea-zone-detail-overlay.md conditional content.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart';

import 'game_fixture.dart';
import 'province_sea_zone_overlay_detail_paths_support.dart';

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay - selected tile + branching paths', () {
    testWidgets(
      'AC: Revealed selected tile renders coordinates + terrain + prospected fields',
      (WidgetTester tester) async {
        final game = demoGameForOverlay;
        final region = demoRegionForOverlay;
        final humanPlayerId = game.players.first.id;
        final selection = firstRevealedLandOverlaySelection(
          game: game,
          region: region,
        );
        expect(
          selection.selectedTileKey,
          isNotNull,
          reason: 'No revealed tile found in demo overlay data',
        );

        await tester.pumpWidget(
          buildProvinceSeaZoneOverlayPathShell(
            game: game,
            region: region,
            displayId: selection.provinceId,
            humanPlayerId: humanPlayerId,
            selectedTileKey: selection.selectedTileKey,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('TILE'), findsOneWidget);
        expect(
          find.text(
            'Coordinates: (${selection.coords.x}, ${selection.coords.y})',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Terrain:'), findsOneWidget);
        expect(find.textContaining('Prospected:'), findsOneWidget);
      },
    );

    testWidgets('AC: Out-of-bounds selected tile shows placeholder "—"', (
      WidgetTester tester,
    ) async {
      final game = demoGameForOverlay;
      final region = demoRegionForOverlay;
      final humanPlayerId = game.players.first.id;
      final firstLandCell = region.cells.firstWhere((c) => !c.isSea);
      final provinceId = '${region.regionId}|${firstLandCell.regionCellId}';
      final badTileKey =
          '${region.regionId}|${firstLandCell.regionCellId}|${region.width + 5}|0';

      await tester.pumpWidget(
        buildProvinceSeaZoneOverlayPathShell(
          game: game,
          region: region,
          displayId: provinceId,
          humanPlayerId: humanPlayerId,
          selectedTileKey: badTileKey,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TILE'), findsOneWidget);
      expect(find.textContaining('Coordinates:'), findsNothing);
      expect(find.text('—'), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'AC: Sea zone display never renders Tile section even when selectedTileKey is provided',
      (WidgetTester tester) async {
        final game = demoGameForOverlay;
        final region = demoRegionForOverlay;
        final humanPlayerId = game.players.first.id;
        final seaZoneId = sampleSeaZoneIdForOverlay;

        String? anyTileKey;
        final byRegion =
            game.worldState.tileKeysByRegionAndProvince[region.regionId];
        if (byRegion != null) {
          for (final tiles in byRegion.values) {
            if (tiles.isNotEmpty) {
              anyTileKey = tiles.first;
              break;
            }
          }
        }
        anyTileKey ??= '${region.regionId}|s0|0|0';

        await tester.pumpWidget(
          buildProvinceSeaZoneOverlayPathShell(
            game: game,
            region: region,
            displayId: seaZoneId,
            humanPlayerId: humanPlayerId,
            selectedTileKey: anyTileKey,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sea zone'), findsOneWidget);
        expect(find.text('POLITICAL'), findsOneWidget);
        expect(find.text('NAVAL'), findsOneWidget);
        expect(find.text('TILE'), findsNothing);
        expect(find.text('Tile'), findsNothing);
        expect(find.textContaining('Coordinates:'), findsNothing);
      },
    );

    testWidgets(
      'AC: New World province overlay resolves units from newWorld state',
      (WidgetTester tester) async {
        final region = seed42MapViewForOverlayPaths.newWorld;
        final game = loadSeed42Game();
        final humanPlayerId = game.players.first.id;
        final selection = firstRevealedLandOverlaySelection(
          game: game,
          region: region,
        );
        expect(
          selection.selectedTileKey,
          isNotNull,
          reason: 'No revealed tile in New World demo province',
        );

        await tester.pumpWidget(
          buildProvinceSeaZoneOverlayPathShell(
            game: game,
            region: region,
            displayId: selection.provinceId,
            humanPlayerId: humanPlayerId,
            selectedTileKey: selection.selectedTileKey,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Province'), findsOneWidget);
        expect(find.text('TILE'), findsOneWidget);
      },
    );
  });
}
