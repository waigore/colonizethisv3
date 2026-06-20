import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/providers/observe_session_provider.dart';
import 'package:colonizethis_map/colonizethis_map.dart' show TileVisibility;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class _FakeGameService extends GameService {
  _FakeGameService(super.box, super.adapter);

  @override
  getMapData(String gameId) {
    return null;
  }
}

/// Minimal OW/NW tile maps + topology for [mapViewDataProvider] integration tests.
class _GameServiceWithMinimalMap extends GameService {
  _GameServiceWithMinimalMap(super.box, super.adapter);

  static final Map<String, MapTopology> _topologyByRegion = {
    'oldWorld': MapTopology(
      nodes: const [
        TopologyNode(
          id: 'p1',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 's1',
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        ),
      ],
      edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
    ),
    'newWorld': MapTopology(
      nodes: const [
        TopologyNode(
          id: 'p1',
          regionId: 'newWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 's1',
          regionId: 'newWorld',
          type: TopologyNodeType.seaZone,
        ),
      ],
      edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
    ),
  };

  static final Map<String, TileMapResult> _tileMapByRegion = {
    'oldWorld': TileMapResult(
      width: 2,
      height: 2,
      grid: [
        ['p1', 's1'],
        ['s1', 's1'],
      ],
    ),
    'newWorld': TileMapResult(
      width: 2,
      height: 2,
      grid: [
        ['p1', 's1'],
        ['s1', 's1'],
      ],
    ),
  };

  static final MapTopology _combinedTopology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'oldWorld|p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'oldWorld|s1',
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 'newWorld|p1',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'newWorld|s1',
        regionId: 'newWorld',
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: const [
      TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|s1'),
      TopologyEdge(id1: 'newWorld|p1', id2: 'newWorld|s1'),
    ],
  );

  @override
  ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    List<WarpLink>? warpLinks,
  })?
  getMapData(String gameId) {
    if (gameId != 'g_map') {
      return null;
    }
    return (
      combinedTopology: _combinedTopology,
      tileMapByRegion: _tileMapByRegion,
      topologyByRegion: _topologyByRegion,
      warpLinks: null,
    );
  }
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_map_view_provider');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  test('mapViewDataProvider returns null when there is no current game', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final mapView = container.read(mapViewDataProvider);
    expect(mapView, isNull);
  });

  test('mapViewDataProvider throws when GameService has no map data', () {
    final game = Game(
      id: 'g1',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => _FakeGameService(gamesBox, GameSaveAdapter()),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      () => container.read(mapViewDataProvider),
      throwsA(
        predicate(
          (e) =>
              e.toString().contains('Missing required map data for gameId=g1'),
        ),
      ),
    );
  });

  test(
    'mapViewDataProvider applies Game.greatPowerColorOverride (player id keys) to faction colors',
    () {
      const portugalRgb = (90, 160, 90);
      final game = Game(
        id: 'g_map',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                displayName: 'OW P1',
                ownerId: 'gp1',
              ),
            ],
            units: const [],
          ),
          newWorld: RegionData(
            provinces: const [
              Province(
                id: 'newWorld|p1',
                regionId: 'newWorld',
                displayName: 'NW P1',
              ),
            ],
            units: const [],
          ),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
        minorNations: const [],
        tribes: const [],
        greatPowerColorOverride: {
          'gp1': [portugalRgb.$1, portugalRgb.$2, portugalRgb.$3],
        },
      );

      final container = ProviderContainer(
        overrides: [
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => _GameServiceWithMinimalMap(gamesBox, GameSaveAdapter()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final mapView = container.read(mapViewDataProvider);
      expect(mapView, isNotNull);
      expect(mapView!.oldWorld.factionColors['gp1'], portugalRgb);
      expect(mapView.newWorld.factionColors['gp1'], portugalRgb);
    },
  );

  test(
    'mapViewDataProvider reveals all tiles in global observe mode',
    () {
      const unrevealedTile = 'oldWorld|p1|0|0';
      final game = Game(
        id: 'g_map',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                displayName: 'OW P1',
                ownerId: 'gp1',
              ),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              'oldWorld|p1': [unrevealedTile],
            },
          },
          playerVisibilityByTile: const {
            'gp1': {unrevealedTile: 'unknown'},
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
          Player(id: 'gp2', displayName: 'France', isHuman: false),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => _GameServiceWithMinimalMap(gamesBox, GameSaveAdapter()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final constrained = container.read(mapViewDataProvider);
      expect(constrained, isNotNull);
      expect(
        constrained!.oldWorld.cellAt(0, 0).visibility,
        TileVisibility.unrevealed,
      );

      final observe = container.read(observeSessionProvider.notifier);
      final handedOff = observe.applyObserveHandoffIfNeeded(game);
      container.read(currentGameProvider.notifier).setGame(handedOff);
      observe.setModeGlobal();

      final globalObserve = container.read(mapViewDataProvider);
      expect(globalObserve, isNotNull);
      for (final cell in globalObserve!.oldWorld.cells) {
        expect(cell.visibility, TileVisibility.visible);
      }
      for (final cell in globalObserve.newWorld.cells) {
        expect(cell.visibility, TileVisibility.visible);
      }
    },
  );

  test(
    'mapViewDataProvider includes non-human civilian markers in global observe',
    () {
      final game = Game(
        id: 'g_map',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
              Province(
                id: 'oldWorld|p2',
                regionId: 'oldWorld',
                ownerId: 'gp2',
              ),
            ],
            units: [
              Unit(
                id: 'u_gp2',
                type: kUnitTypeBuilder,
                ownerId: 'gp2',
                locationProvinceId: 'oldWorld|p2',
                tileKey: 'oldWorld|p2|1|0',
                status: UnitStatus.idle,
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'France', isHuman: false),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          currentGameProvider.overrideWith(CurrentGameNotifier.new),
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => _GameServiceWithMinimalMap(gamesBox, GameSaveAdapter()),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(currentGameProvider.notifier).setGame(game);

      expect(
        container.read(mapViewDataProvider)!.oldWorld.civilianTileMarkers,
        isEmpty,
      );

      final observe = container.read(observeSessionProvider.notifier);
      final handedOff = observe.applyObserveHandoffIfNeeded(game);
      container.read(currentGameProvider.notifier).setGame(handedOff);
      observe.setModeGlobal();

      final markers =
          container.read(mapViewDataProvider)!.oldWorld.civilianTileMarkers;
      expect(markers, hasLength(1));
      expect(markers.single.tileKey, 'oldWorld|p2|1|0');
    },
  );
}
