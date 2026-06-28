// Widget tests for canonical terrain display names in the province overlay.
// SPEC/game/resource-terrain-region-rules.md § Player-facing terrain display
// names; issue #3573 R13 / AC11.

import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';

import 'support/app_shell_harness.dart';

const _regionId = 'oldWorld';
const _localProvinceId = 'pTerrainTest';
String get _fullProvinceId => '$_regionId|$_localProvinceId';

String _tileKey(int x, int y) => '$_fullProvinceId|$x|$y';

RegionMapViewData _regionWithCell(CellViewData cell) {
  return RegionMapViewData(
    regionId: _regionId,
    width: 1,
    height: 1,
    cellSize: 32,
    cells: [cell],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {'gp1'},
    terrainColors: const {},
  );
}

Game _minimalGame(String tk) {
  return Game(
    id: 'terrain_label_test',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _fullProvinceId,
            regionId: _regionId,
            displayName: 'TerrainTest',
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        _regionId: {
          _fullProvinceId: [tk],
        },
      },
      playerVisibilityByTile: {
        'gp1': {tk: 'fullyVisible'},
      },
      playerProspectedTiles: {
        'gp1': {tk},
      },
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
    ],
  );
}

PlayerView _omniscientView(String tk) {
  return PlayerView(
    playerId: 'gp1',
    player: const Player(
      id: 'gp1',
      displayName: 'Human',
      isHuman: true,
      treasury: 0,
    ),
    ownUnitsById: const {},
    provincesById: const {},
    visibilityByTile: {tk: VisibilityLevel.fullyVisible},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

Future<void> _pumpOverlay(
  WidgetTester tester,
  CellViewData cell,
  String tk,
) async {
  await pumpAppShell(
    tester,
    settle: true,
    child: Scaffold(
      body: SizedBox(
        width: 800,
        child: ProvinceSeaZoneDetailOverlay(
          game: _minimalGame(tk),
          region: _regionWithCell(cell),
          displayId: _fullProvinceId,
          selectedTileKey: tk,
          humanPlayerId: 'gp1',
          playerView: _omniscientView(tk),
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay terrain display name (#3573 AC11)', () {
    testWidgets(
      'hardwood forest tile (enum) shows "Hardwood Forest", never raw enum name',
      (tester) async {
        final tk = _tileKey(0, 0);
        await _pumpOverlay(
          tester,
          const CellViewData(
            x: 0,
            y: 0,
            regionCellId: _localProvinceId,
            isSea: false,
            terrainTypeId: 'hardwoodForest',
            terrainType: TerrainType.hardwoodForest,
            visibility: TileVisibility.visible,
          ),
          tk,
        );

        expect(find.textContaining('Hardwood Forest'), findsWidgets);
        expect(find.textContaining('hardwoodForest'), findsNothing);
        expect(find.textContaining('Hardwood forest'), findsNothing);
        expect(find.textContaining('HardwoodForest'), findsNothing);
      },
    );

    testWidgets(
      'scrub forest tile (enum) shows "Scrub Forest", never raw enum name',
      (tester) async {
        final tk = _tileKey(0, 0);
        await _pumpOverlay(
          tester,
          const CellViewData(
            x: 0,
            y: 0,
            regionCellId: _localProvinceId,
            isSea: false,
            terrainTypeId: 'scrubForest',
            terrainType: TerrainType.scrubForest,
            visibility: TileVisibility.visible,
          ),
          tk,
        );

        expect(find.textContaining('Scrub Forest'), findsWidgets);
        expect(find.textContaining('scrubForest'), findsNothing);
        expect(find.textContaining('Scrub forest'), findsNothing);
        expect(find.textContaining('ScrubForest'), findsNothing);
      },
    );

    testWidgets(
      'string-id fallback (no enum) spaces camelCase to "Hardwood Forest" (R13.5)',
      (tester) async {
        final tk = _tileKey(0, 0);
        await _pumpOverlay(
          tester,
          const CellViewData(
            x: 0,
            y: 0,
            regionCellId: _localProvinceId,
            isSea: false,
            terrainTypeId: 'hardwoodForest',
            visibility: TileVisibility.visible,
          ),
          tk,
        );

        expect(find.textContaining('Hardwood Forest'), findsWidgets);
        expect(find.textContaining('HardwoodForest'), findsNothing);
        expect(find.textContaining('hardwoodForest'), findsNothing);
      },
    );
  });
}
