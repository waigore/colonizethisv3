// Shared fixtures for Upgrade town radial-catalog tests (Refs #4570, #4747).

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_catalog.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'province_shortcut_host_emit_fixtures.dart';

const String kUpgradeTownCatalogHumanPlayerId =
    kProvinceShortcutHostHumanPlayerId;
const String kUpgradeTownCatalogProvinceId =
    kProvinceShortcutHostOldWorldProvinceId;
const String kUpgradeTownCatalogTownTileKey = kProvinceShortcutHostTileKey;
const String kUpgradeTownCatalogOtherTileKey =
    kProvinceShortcutHostSecondTileKey;

final MapTopology kUpgradeTownCatalogTopology =
    provinceShortcutHostCombinedTopology(includeSea: false);
final Map<String, TileMapResult> kUpgradeTownCatalogTileMapByRegion =
    provinceShortcutHostTileMapByRegion(
      width: 2,
      height: 1,
      grid: const [
        ['p1', 'p1'],
      ],
    );

GameMapData get kUpgradeTownCatalogMapData => (
  combinedTopology: kUpgradeTownCatalogTopology,
  tileMapByRegion: kUpgradeTownCatalogTileMapByRegion,
  topologyByRegion: provinceShortcutHostTopologyByRegion(includeSea: false),
  warpLinks: null,
);

Game upgradeTownCatalogGame() {
  return Game(
    id: 'g_tile_radial_upgrade_town_host',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: kUpgradeTownCatalogProvinceId,
            regionId: 'oldWorld',
            ownerId: kUpgradeTownCatalogHumanPlayerId,
            townDevelopmentLevel: 2,
            townTileKey: kUpgradeTownCatalogTownTileKey,
          ),
        ],
        units: [
          Unit(
            id: 'u_builder',
            type: kUnitTypeBuilder,
            ownerId: kUpgradeTownCatalogHumanPlayerId,
            locationProvinceId: kUpgradeTownCatalogProvinceId,
            tileKey: kUpgradeTownCatalogTownTileKey,
            status: UnitStatus.idle,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      resourceByTileKey: const {
        kUpgradeTownCatalogTownTileKey: 'grain',
        kUpgradeTownCatalogOtherTileKey: 'grain',
      },
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          kUpgradeTownCatalogProvinceId: [
            kUpgradeTownCatalogTownTileKey,
            kUpgradeTownCatalogOtherTileKey,
          ],
        },
      },
      playerVisibilityByTile: {
        kUpgradeTownCatalogHumanPlayerId: {
          kUpgradeTownCatalogTownTileKey: 'fullyVisible',
          kUpgradeTownCatalogOtherTileKey: 'fullyVisible',
        },
      },
    ),
    players: [
      Player(
        id: kUpgradeTownCatalogHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: kUpgradeTownCatalogProvinceId,
        stockpile: const Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
        techUnlocked: const {kTechIdNationalBureaucracy: true},
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

RegionMapViewData upgradeTownCatalogRegion() {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 2,
    height: 1,
    cellSize: 16,
    cells: const [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        terrainType: TerrainType.plains,
        resourceId: 'grain',
        ownerFactionId: kUpgradeTownCatalogHumanPlayerId,
        provinceDisplayName: 'Wessex',
        visibility: TileVisibility.visible,
      ),
      CellViewData(
        x: 1,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        terrainType: TerrainType.plains,
        resourceId: 'grain',
        ownerFactionId: kUpgradeTownCatalogHumanPlayerId,
        provinceDisplayName: 'Wessex',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: {kUpgradeTownCatalogHumanPlayerId},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {
      'oldWorld|p1': kUpgradeTownCatalogHumanPlayerId,
    },
  );
}

Set<TileRadialCatalogAction> upgradeTownCatalogActions(
  TileRadialCatalogLayout layout,
) {
  return {
    ...layout.wedges.map((s) => s.action),
    ...layout.moreRemainder.map((s) => s.action),
  };
}

PerPlayerWorkTargetSelectionCache upgradeTownCatalogCache(Game game) {
  final playerView = buildPlayerView(
    game,
    kUpgradeTownCatalogTopology,
    kUpgradeTownCatalogHumanPlayerId,
  );
  return PerPlayerWorkTargetSelectionCache()..refresh(
    WorkTargetSelectionSnapshot(
      game: game,
      playerId: kUpgradeTownCatalogHumanPlayerId,
      playerView: playerView,
      topology: kUpgradeTownCatalogTopology,
      currentOrders: const Orders(),
      tileMapByRegion: kUpgradeTownCatalogTileMapByRegion,
    ),
  );
}
