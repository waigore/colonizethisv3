// Tests for ProvinceSeaZoneDetailOverlay tile selection and branching paths.
// Covers SPEC/ui/province-sea-zone-detail-overlay.md conditional content.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_logic/colonizethis_logic.dart' show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart';
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';

import 'support/game_fixture.dart';
import 'support/map_view_fixture.dart';

void main() {
  suppressLogsForTests();

  // Load the committed seed-42 map-view fixture once per isolate instead of
  // paying the ~7-11s procedural map generation of getDebugInitGameResult()
  // (Refs #3656). The fixture's combinedTopology is byte-identical to the live
  // generator's for the default config, so playerView visibility is unchanged.
  final seed42MapView = loadSeed42MapViewData();
  final seed42CombinedTopology = seed42MapView.combinedTopology;

  Widget buildOverlay({
    required Game game,
    required RegionMapViewData region,
    required String displayId,
    required String humanPlayerId,
    String? selectedTileKey,
    VoidCallback? onClose,
  }) {
    final playerView =
        buildPlayerView(game, seed42CombinedTopology, humanPlayerId);
    return MaterialApp(
      home: Scaffold(
        body: ProvinceSeaZoneDetailOverlay(
          game: game,
          region: region,
          displayId: displayId,
          selectedTileKey: selectedTileKey,
          humanPlayerId: humanPlayerId,
          playerView: playerView,
          onClose: onClose,
        ),
      ),
    );
  }

  ({int x, int y}) coordsFromTileKey(String tileKey) {
    final parts = tileKey.split('|');
    // Tile keys are expected to include x/y at indexes 2 and 3.
    final xPart = parts.length > 2 ? parts[2] : '';
    final yPart = parts.length > 3 ? parts[3] : '';
    final x = int.tryParse(xPart) ?? -1;
    final y = int.tryParse(yPart) ?? -1;
    return (x: x, y: y);
  }

  group('ProvinceSeaZoneDetailOverlay - selected tile + branching paths', () {
    testWidgets(
        'AC: Revealed selected tile renders coordinates + terrain + prospected fields',
        (WidgetTester tester) async {
      final game = demoGameForOverlay;
      final region = demoRegionForOverlay;
      final humanPlayerId = game.players.first.id;

      // Pick a land province with at least one revealed tile for hovering.
      final landCell = region.cells.firstWhere(
        (c) => !c.isSea && c.visibility != TileVisibility.unrevealed,
      );
      final provinceId = '${region.regionId}|${landCell.regionCellId}';
      final possibleTiles =
          game.worldState.tileKeysByRegionAndProvince[region.regionId]?[provinceId] ??
              const <String>[];

      String? selectedTileKey;
      ({int x, int y}) coords = (x: -1, y: -1);
      for (final tk in possibleTiles) {
        final c = coordsFromTileKey(tk);
        // Mirror overlay lookup: it uses region.cellAt(x,y) and checks visibility.
        if (c.x < 0 || c.x >= region.width || c.y < 0 || c.y >= region.height) {
          continue;
        }
        final cell = region.cellAt(c.x, c.y);
        if (cell.visibility != TileVisibility.unrevealed) {
          selectedTileKey = tk;
          coords = c;
          break;
        }
      }

      // If demo data is unexpectedly unrevealed, fail with a clear message.
      expect(selectedTileKey, isNotNull, reason: 'No revealed tile found in demo overlay data');

      await tester.pumpWidget(
        buildOverlay(
          game: game,
          region: region,
          displayId: provinceId,
          humanPlayerId: humanPlayerId,
          selectedTileKey: selectedTileKey,
        ),
      );
      await tester.pumpAndSettle();

      // Section headers render via CtSectionLabel (Refs #2865 S4) which
      // upper-cases the label per SPEC § Dark-theme section labels.
      expect(find.text('TILE'), findsOneWidget);
      expect(find.text('Coordinates: (${coords.x}, ${coords.y})'), findsOneWidget);
      expect(find.textContaining('Terrain:'), findsOneWidget);
      expect(find.textContaining('Prospected:'), findsOneWidget);
    });

    testWidgets('AC: Out-of-bounds selected tile shows placeholder "—"', (
      WidgetTester tester,
    ) async {
      final game = demoGameForOverlay;
      final region = demoRegionForOverlay;
      final humanPlayerId = game.players.first.id;

      // Use the overlay's expected tile-key format but push x outside bounds.
      final firstLandCell = region.cells.firstWhere((c) => !c.isSea);
      final provinceId = '${region.regionId}|${firstLandCell.regionCellId}';
      final badTileKey = '${region.regionId}|${firstLandCell.regionCellId}|${region.width + 5}|0';

      await tester.pumpWidget(
        buildOverlay(
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

      // Provide some hovered tile key; it should be ignored in sea-zone mode.
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
        buildOverlay(
          game: game,
          region: region,
          displayId: seaZoneId,
          humanPlayerId: humanPlayerId,
          selectedTileKey: anyTileKey,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sea zone'), findsOneWidget);
      // Section headers render via CtSectionLabel (Refs #2865 S4) which
      // upper-cases the label per SPEC § Dark-theme section labels.
      expect(find.text('POLITICAL'), findsOneWidget);
      expect(find.text('NAVAL'), findsOneWidget);
      // Sea-zone overlay never emits the Tile section header in any casing.
      expect(find.text('TILE'), findsNothing);
      expect(find.text('Tile'), findsNothing);
      expect(find.textContaining('Coordinates:'), findsNothing);
    });

    testWidgets('AC: New World province overlay resolves units from newWorld state', (
      WidgetTester tester,
    ) async {
      final region = seed42MapView.newWorld;
      final game = loadSeed42Game();
      final humanPlayerId = game.players.first.id;
      final landCell = region.cells.firstWhere((c) => !c.isSea);
      final provinceId = '${region.regionId}|${landCell.regionCellId}';
      final possibleTiles =
          game.worldState.tileKeysByRegionAndProvince[region.regionId]?[provinceId] ??
              const <String>[];
      String? selectedTileKey;
      for (final tk in possibleTiles) {
        final c = coordsFromTileKey(tk);
        if (c.x < 0 || c.x >= region.width || c.y < 0 || c.y >= region.height) continue;
        final cell = region.cellAt(c.x, c.y);
        if (cell.visibility != TileVisibility.unrevealed) {
          selectedTileKey = tk;
          break;
        }
      }
      expect(selectedTileKey, isNotNull, reason: 'No revealed tile in New World demo province');

      await tester.pumpWidget(
        buildOverlay(
          game: game,
          region: region,
          displayId: provinceId,
          humanPlayerId: humanPlayerId,
          selectedTileKey: selectedTileKey,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Province'), findsOneWidget);
      // Section headers render via CtSectionLabel (Refs #2865 S4) which
      // upper-cases the label per SPEC § Dark-theme section labels.
      expect(find.text('TILE'), findsOneWidget);
    });

    testWidgets('AC: Narrow layout uses tab strip for overlay sections', (
      WidgetTester tester,
    ) async {
      final binding = tester.view;
      final oldSize = binding.physicalSize;
      final oldRatio = binding.devicePixelRatio;
      addTearDown(() {
        binding.physicalSize = oldSize;
        binding.devicePixelRatio = oldRatio;
      });
      // Tall surface so narrow maxHeight (⅓ screen) fits tab content without overflow.
      binding.physicalSize = const Size(400, 2000);
      binding.devicePixelRatio = 1.0;

      final game = demoGameForOverlay;
      final region = demoRegionForOverlay;
      final humanPlayerId = game.players.first.id;
      final landCell = region.cells.firstWhere(
        (c) => !c.isSea && c.visibility != TileVisibility.unrevealed,
      );
      final provinceId = '${region.regionId}|${landCell.regionCellId}';
      final possibleTiles =
          game.worldState.tileKeysByRegionAndProvince[region.regionId]?[provinceId] ??
              const <String>[];
      String? selectedTileKey;
      for (final tk in possibleTiles) {
        final c = coordsFromTileKey(tk);
        if (c.x < 0 || c.x >= region.width || c.y < 0 || c.y >= region.height) continue;
        final cell = region.cellAt(c.x, c.y);
        if (cell.visibility != TileVisibility.unrevealed) {
          selectedTileKey = tk;
          break;
        }
      }
      expect(selectedTileKey, isNotNull);

      await tester.pumpWidget(
        buildOverlay(
          game: game,
          region: region,
          displayId: provinceId,
          humanPlayerId: humanPlayerId,
          selectedTileKey: selectedTileKey,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CtTabStrip), findsOneWidget);
    });

    testWidgets(
      'AC: Wide layout renders a single scrollable column of all six '
      'sections without a tab strip',
      (WidgetTester tester) async {
        // SPEC § Layout / Acceptance criteria — "Wide viewport side panel":
        // at viewport width >= the shell breakpoint the overlay renders the
        // sections as a single scrollable column and **without a tab strip**.
        // The narrow case above pins the CtTabStrip-present path; this is the
        // complementary wide-path regression guard (CtTabStrip absent +
        // scrollable column) so a regression that re-applies the narrow tab
        // layout to wide hosts fails explicitly.
        final binding = tester.view;
        final oldSize = binding.physicalSize;
        final oldRatio = binding.devicePixelRatio;
        addTearDown(() {
          binding.physicalSize = oldSize;
          binding.devicePixelRatio = oldRatio;
        });
        // Width clearly >= kNarrowBreakpoint (600); tall so the wide
        // scrollable column lays out all six sections without overflow.
        binding.physicalSize = const Size(1200, 2000);
        binding.devicePixelRatio = 1.0;

        final game = demoGameForOverlay;
        final region = demoRegionForOverlay;
        final humanPlayerId = game.players.first.id;
        final landCell = region.cells.firstWhere(
          (c) => !c.isSea && c.visibility != TileVisibility.unrevealed,
        );
        final provinceId = '${region.regionId}|${landCell.regionCellId}';
        final possibleTiles =
            game.worldState.tileKeysByRegionAndProvince[region.regionId]?[provinceId] ??
                const <String>[];
        String? selectedTileKey;
        for (final tk in possibleTiles) {
          final c = coordsFromTileKey(tk);
          if (c.x < 0 || c.x >= region.width || c.y < 0 || c.y >= region.height) {
            continue;
          }
          final cell = region.cellAt(c.x, c.y);
          if (cell.visibility != TileVisibility.unrevealed) {
            selectedTileKey = tk;
            break;
          }
        }
        expect(selectedTileKey, isNotNull);

        await tester.pumpWidget(
          buildOverlay(
            game: game,
            region: region,
            displayId: provinceId,
            humanPlayerId: humanPlayerId,
            selectedTileKey: selectedTileKey,
          ),
        );
        await tester.pumpAndSettle();

        // Primary AC: the wide side panel must not use a tab strip.
        expect(find.byType(CtTabStrip), findsNothing);
        // The sections render as a single scrollable column.
        expect(
          find.descendant(
            of: find.byType(ProvinceSeaZoneDetailOverlay),
            matching: find.byType(SingleChildScrollView),
          ),
          findsOneWidget,
        );
        // All six province sections are present at once (one CtSectionLabel
        // header each), confirming the single-column layout rather than the
        // one-section-per-tab narrow layout.
        expect(find.byType(CtSectionLabel), findsNWidgets(6));
        for (final header in const <String>[
          'POLITICAL',
          'TILE',
          'ECONOMIC',
          'MILITARY',
          'CIVILIAN',
          'NAVAL',
        ]) {
          expect(
            find.text(header),
            findsOneWidget,
            reason: 'Wide layout must render the $header section header in the '
                'single scrollable column.',
          );
        }
      },
    );
  });
}

