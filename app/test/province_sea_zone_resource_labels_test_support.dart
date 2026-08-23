// Shared MAP20001 resource-label overlay fixtures (Refs #4606 Slice D).
// SPEC/ui/province-sea-zone-detail-overlay.md, SPEC/ui/pixel-art-ui-catalog.md.

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_test_harness.dart';

const resourceLabelRegionId = 'oldWorld';
const resourceLabelLocalProvinceId = 'pResTest';
String get resourceLabelFullProvinceId =>
    '$resourceLabelRegionId|$resourceLabelLocalProvinceId';

String resourceLabelTileKey(int x, int y) =>
    '$resourceLabelFullProvinceId|$x|$y';

RegionMapViewData resourceLabelRegionWithCells(
  List<CellViewData> cells,
  int w,
  int h,
) {
  return RegionMapViewData(
    regionId: resourceLabelRegionId,
    width: w,
    height: h,
    cellSize: 32,
    cells: cells,
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {'gp1'},
    terrainColors: const {},
  );
}

Game resourceLabelMinimalGame({
  required Map<String, List<String>> tileKeysByProvince,
  Map<String, String> resourceByTileKey = const {},
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
  Map<String, Set<String>> playerProspectedTiles = const {},
}) {
  return Game(
    id: 'res_label_test',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: resourceLabelFullProvinceId,
            regionId: resourceLabelRegionId,
            displayName: 'ResTest',
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {resourceLabelRegionId: tileKeysByProvince},
      resourceByTileKey: resourceByTileKey,
      playerVisibilityByTile: playerVisibilityByTile,
      playerProspectedTiles: playerProspectedTiles,
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
    ],
  );
}

PlayerView resourceLabelOmniscientView(Iterable<String> keys) {
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
    visibilityByTile: {for (final k in keys) k: VisibilityLevel.fullyVisible},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

Future<void> pumpResourceLabelOverlay(
  WidgetTester tester, {
  required Game game,
  required RegionMapViewData region,
  required String selectedTileKey,
  required Iterable<String> viewTileKeys,
}) async {
  await tester.pumpWidget(
    buildProvinceOverlayDarkThemeShell(
      game: game,
      region: region,
      displayId: resourceLabelFullProvinceId,
      selectedTileKey: selectedTileKey,
      humanPlayerId: 'gp1',
      playerView: resourceLabelOmniscientView(viewTileKeys),
      shellWidth: 800,
    ),
  );
  await tester.pumpAndSettle();
}
