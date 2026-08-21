// AC-3 emit: Upgrade town enabled only on town tile; target key is town tile.
// SPEC/ui/components/tile-radial-catalog.md (Refs #4570).

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_catalog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_emit.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_shortcut_host_emit_fixtures.dart';

const String _kHumanPlayerId = 'gp1';
const String _kProvinceId = 'oldWorld|p1';
const String _kTownTileKey = 'oldWorld|p1|0|0';
const String _kOtherTileKey = 'oldWorld|p1|1|0';

final MapTopology _combinedTopology = provinceShortcutHostCombinedTopology(
  includeSea: false,
);
final Map<String, TileMapResult> _tileMapByRegion =
    provinceShortcutHostTileMapByRegion(
      width: 2,
      height: 1,
      grid: const [
        ['p1', 'p1'],
      ],
    );
final Map<String, MapTopology> _topologyByRegion =
    provinceShortcutHostTopologyByRegion(includeSea: false);

GameMapData get _mapData => (
  combinedTopology: _combinedTopology,
  tileMapByRegion: _tileMapByRegion,
  topologyByRegion: _topologyByRegion,
  warpLinks: null,
);

Game _game() {
  return Game(
    id: 'g_tile_radial_upgrade_town_emit',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _kProvinceId,
            regionId: 'oldWorld',
            ownerId: _kHumanPlayerId,
            townDevelopmentLevel: 2,
            townTileKey: _kTownTileKey,
          ),
        ],
        units: [
          Unit(
            id: 'u_builder',
            type: kUnitTypeBuilder,
            ownerId: _kHumanPlayerId,
            locationProvinceId: _kProvinceId,
            tileKey: _kTownTileKey,
            status: UnitStatus.idle,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      resourceByTileKey: const {
        _kTownTileKey: 'grain',
        _kOtherTileKey: 'grain',
      },
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          _kProvinceId: [_kTownTileKey, _kOtherTileKey],
        },
      },
      playerVisibilityByTile: {
        _kHumanPlayerId: {
          _kTownTileKey: 'fullyVisible',
          _kOtherTileKey: 'fullyVisible',
        },
      },
    ),
    players: [
      Player(
        id: _kHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: _kProvinceId,
        stockpile: const Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
        techUnlocked: const {kTechIdNationalBureaucracy: true},
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

RegionMapViewData _region() {
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
        ownerFactionId: _kHumanPlayerId,
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
        ownerFactionId: _kHumanPlayerId,
        provinceDisplayName: 'Wessex',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: {_kHumanPlayerId},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {
      'oldWorld|p1': _kHumanPlayerId,
    },
  );
}

PerPlayerWorkTargetSelectionCache _cache(Game game) {
  final playerView = buildPlayerView(game, _combinedTopology, _kHumanPlayerId);
  return PerPlayerWorkTargetSelectionCache()..refresh(
    WorkTargetSelectionSnapshot(
      game: game,
      playerId: _kHumanPlayerId,
      playerView: playerView,
      topology: _combinedTopology,
      currentOrders: const Orders(),
      tileMapByRegion: _tileMapByRegion,
    ),
  );
}

void main() {
  suppressLogsForTests();

  test(
    'enabled Upgrade town on town tile emits builder shortcut with town key',
    () async {
      final game = _game();
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final events = <OpenCivilianUnitsPanelEvent>[];
      final sub = bus.on<OpenCivilianUnitsPanelEvent>().listen(events.add);
      addTearDown(sub.cancel);
      final playerView = buildPlayerView(
        game,
        _combinedTopology,
        _kHumanPlayerId,
      );
      emitTileRadialCatalogAction(
        action: TileRadialCatalogAction.upgradeTown,
        tileKey: _kTownTileKey,
        game: game,
        humanPlayerId: _kHumanPlayerId,
        region: _region(),
        playerView: playerView,
        workTargetSelectionCache: _cache(game),
        draftOrders: const Orders(),
        mapData: _mapData,
        bus: bus,
      );
      await pumpEventQueue();
      expect(events, hasLength(1));
      expect(events.single.builderOnly, isTrue);
      expect(events.single.upgradeTownShortcutTargetTileKey, _kTownTileKey);
    },
  );

  test(
    'Upgrade town on a non-town tile in the same province is a silent no-op',
    () async {
      final game = _game();
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final events = <OpenCivilianUnitsPanelEvent>[];
      final sub = bus.on<OpenCivilianUnitsPanelEvent>().listen(events.add);
      addTearDown(sub.cancel);
      final playerView = buildPlayerView(
        game,
        _combinedTopology,
        _kHumanPlayerId,
      );
      emitTileRadialCatalogAction(
        action: TileRadialCatalogAction.upgradeTown,
        tileKey: _kOtherTileKey,
        game: game,
        humanPlayerId: _kHumanPlayerId,
        region: _region(),
        playerView: playerView,
        workTargetSelectionCache: _cache(game),
        draftOrders: const Orders(),
        mapData: _mapData,
        bus: bus,
      );
      await pumpEventQueue();
      expect(events, isEmpty);
    },
  );
}
