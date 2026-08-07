// Visual golden for MAP20001 Military fort status line (Refs #4280).
// SPEC/ui/province-sea-zone-detail-overlay.md § Military fort posture.

import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'province_overlay_test_harness.dart';

Game _fortOverlayGame({required int fortLevel}) {
  final humanId = 'gp_fort_overlay';
  const provinceId = 'oldWorld|pFort';
  const tileKey = 'oldWorld|pFort|0|0';
  return Game(
    id: 'g_fort_overlay',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceId,
            regionId: 'oldWorld',
            ownerId: humanId,
            townTileKey: tileKey,
            fortLevel: fortLevel,
          ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: {
        'oldWorld': {provinceId: [tileKey]},
      },
      tileState: TileMapState(),
      playerVisibilityByTile: {
        humanId: {tileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: humanId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: provinceId,
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

RegionMapViewData _fortOverlayRegion() {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 1,
    height: 1,
    cellSize: 16,
    cells: const [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'pFort',
        isSea: false,
        terrainType: TerrainType.plains,
        resourceId: 'grain',
        ownerFactionId: 'gp_fort_overlay',
        provinceDisplayName: 'Fort Province',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: {'gp_fort_overlay'},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {
      'oldWorld|pFort': 'gp_fort_overlay',
    },
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: Military section shows Stone fort status line (Refs #4280)',
    (WidgetTester tester) async {
      await configureGoldenSurface(tester, size: const Size(600, 1000));
      configureGoldenView(
        tester,
        physicalSize: const Size(600, 1000),
        devicePixelRatio: 1.0,
      );

      const boundaryKey = ValueKey('province_overlay_fort_military_golden');
      final game = _fortOverlayGame(fortLevel: 2);
      final humanId = game.players.first.id;
      final provinceId = game.worldState.oldWorld.provinces.first.id;
      final tileKey = game.worldState.oldWorld.provinces.first.townTileKey!;
      final playerView = demoOverlayPlayerView(game);
      final region = _fortOverlayRegion();

      await tester.pumpWidget(
        wrapGoldenBoundary(
          boundaryKey: boundaryKey,
          child: SizedBox(
            width: 460,
            height: 900,
            child: buildProvinceOverlayDarkThemeShell(
              game: game,
              displayId: provinceId,
              region: region,
              selectedTileKey: tileKey,
              humanPlayerId: humanId,
              playerView: playerView,
              omniscientDetail: true,
              shellWidth: 460,
            ),
          ),
        ),
      );
      await pumpForGolden(tester);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Stone fort siege'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/province_overlay_fort_military_stone.png'),
      );
    },
  );
}
