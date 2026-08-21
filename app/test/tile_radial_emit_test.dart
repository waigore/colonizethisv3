// MAP30001 / MAP30002 catalog emit parity with MAP20001 shortcuts. Refs #4440.

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

const String _kHumanPlayerId = 'gp1';
const String _kProvinceId = 'oldWorld|p1';
const String _kTileKey = 'oldWorld|p1|0|0';

final MapTopology _topology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

RegionMapViewData _region() {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 1,
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
        provinceDisplayName: 'Test Province',
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

Game _game() {
  return Game(
    id: 'g_tile_radial_emit',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _kProvinceId,
            regionId: 'oldWorld',
            ownerId: _kHumanPlayerId,
          ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          _kProvinceId: [_kTileKey],
        },
      },
      playerVisibilityByTile: {
        _kHumanPlayerId: {_kTileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: _kHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: _kProvinceId,
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

void main() {
  suppressLogsForTests();

  test('Explore catalog event matches MAP20001 explorer shortcut fields', () {
    final event = tileRadialCatalogPanelEvent(
      TileRadialCatalogAction.explore,
      _kTileKey,
    );
    expect(event.explorerOnly, isTrue);
    expect(event.builderOnly, isFalse);
    expect(event.exploreShortcutTargetTileKey, _kTileKey);
    expect(event.prospectShortcutTargetTileKey, isNull);
    expect(event.buildImprovementShortcutTargetTileKey, isNull);
  });

  test('Prospect catalog event matches MAP20001 explorer prospect fields', () {
    final event = tileRadialCatalogPanelEvent(
      TileRadialCatalogAction.prospect,
      _kTileKey,
    );
    expect(event.explorerOnly, isTrue);
    expect(event.prospectShortcutTargetTileKey, _kTileKey);
    expect(event.exploreShortcutTargetTileKey, isNull);
  });

  test(
    'Build improvement catalog event matches MAP20001 builder shortcut fields',
    () {
      final event = tileRadialCatalogPanelEvent(
        TileRadialCatalogAction.buildImprovement,
        _kTileKey,
      );
      expect(event.builderOnly, isTrue);
      expect(event.explorerOnly, isFalse);
      expect(event.buildImprovementShortcutTargetTileKey, _kTileKey);
      expect(event.exploreShortcutTargetTileKey, isNull);
    },
  );

  test('Build road catalog event matches MAP20001 engineer shortcut fields', () {
    final event = tileRadialCatalogPanelEvent(
      TileRadialCatalogAction.buildRoad,
      _kTileKey,
    );
    expect(event.engineerOnly, isTrue);
    expect(event.buildRoadShortcutTargetTileKey, _kTileKey);
    expect(event.buildImprovementShortcutTargetTileKey, isNull);
  });

  test(
    'Purchase land catalog event matches MAP20001 merchant shortcut fields',
    () {
      final event = tileRadialCatalogPanelEvent(
        TileRadialCatalogAction.purchaseLand,
        _kTileKey,
      );
      expect(event.merchantOnly, isTrue);
      expect(event.purchaseLandShortcutTargetTileKey, _kTileKey);
    },
  );

  test(
    'Upgrade town catalog event matches MAP20001 builder upgrade fields',
    () {
      final event = tileRadialCatalogPanelEvent(
        TileRadialCatalogAction.upgradeTown,
        _kTileKey,
      );
      expect(event.builderOnly, isTrue);
      expect(event.upgradeTownShortcutTargetTileKey, _kTileKey);
    },
  );

  test('Build port catalog event matches MAP20001 engineer port fields', () {
    final event = tileRadialCatalogPanelEvent(
      TileRadialCatalogAction.buildPort,
      _kTileKey,
    );
    expect(event.engineerOnly, isTrue);
    expect(event.buildPortShortcutTargetTileKey, _kTileKey);
  });

  test(
    'Build railroad catalog event matches MAP20001 rail-builder fields',
    () {
      final event = tileRadialCatalogPanelEvent(
        TileRadialCatalogAction.buildRail,
        _kTileKey,
      );
      expect(event.railBuilderOnly, isTrue);
      expect(event.buildRailShortcutTargetTileKey, _kTileKey);
    },
  );

  test('Build fort catalog event matches MAP20001 engineer fort fields', () {
    final event = tileRadialCatalogPanelEvent(
      TileRadialCatalogAction.buildFort,
      _kTileKey,
    );
    expect(event.engineerOnly, isTrue);
    expect(event.buildFortShortcutTargetTileKey, _kTileKey);
  });

  test('Explore with no explorer is a silent no-op', () {
    final game = _game();
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    final events = <OpenCivilianUnitsPanelEvent>[];
    final sub = bus.on<OpenCivilianUnitsPanelEvent>().listen(events.add);
    addTearDown(sub.cancel);
    emitTileRadialCatalogAction(
      action: TileRadialCatalogAction.explore,
      tileKey: _kTileKey,
      game: game,
      humanPlayerId: _kHumanPlayerId,
      region: _region(),
      playerView: buildPlayerView(game, _topology, _kHumanPlayerId),
      workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(),
      draftOrders: const Orders(),
      mapData: null,
      bus: bus,
    );
    expect(events, isEmpty);
  });
}
