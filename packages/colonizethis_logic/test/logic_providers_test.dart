import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/di.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('logic DI providers', () {
    test('orderSuggestionApiProvider override is readable from container', () {
      final fake = _SpyOrderSuggestionAPI();
      final container = ProviderContainer(
        overrides: [
          orderSuggestionApiProvider.overrideWith((ref) => fake),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(orderSuggestionApiProvider), same(fake));
    });

    test('generateOrdersForPlayerFullAI uses API from overridden provider', () {
      final fake = _SpyOrderSuggestionAPI();
      final container = ProviderContainer(
        overrides: [
          orderSuggestionApiProvider.overrideWith((ref) => fake),
        ],
      );
      addTearDown(container.dispose);

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'gp1'),
            ],
            units: [
              Unit(id: 'u1', type: 'grenadiers', ownerId: 'gp1', locationProvinceId: 'oldWorld|P1'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {'oldWorld|P1|0|0': 'fullyVisible'},
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI', isHuman: false),
        ],
        globalGameSeed: 1,
        aiSeedByGpId: const {'gp1': 1},
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [],
      );

      generateOrdersForPlayerFullAI(
        game,
        topology,
        'gp1',
        orderSuggestionApi: container.read(orderSuggestionApiProvider),
      );

      expect(fake.suggestMoveCalls, greaterThan(0));
      expect(fake.suggestArmyMoveCalls, greaterThan(0));
    });

    test('generateOrdersForPlayerFullAI forwards tileMapByRegion to suggestWorkOrders', () {
      final fake = _SpyOrderSuggestionAPI();
      final container = ProviderContainer(
        overrides: [
          orderSuggestionApiProvider.overrideWith((ref) => fake),
        ],
      );
      addTearDown(container.dispose);

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'gp1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {'oldWorld|P1|0|0': 'fullyVisible'},
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI', isHuman: false),
        ],
        globalGameSeed: 1,
        aiSeedByGpId: const {'gp1': 1},
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final tileMap = {
        'oldWorld': TileMapResult(
          width: 1,
          height: 1,
          grid: const [
            ['P1'],
          ],
          terrainGrid: [
            [TerrainType.plains],
          ],
        ),
      };

      generateOrdersForPlayerFullAI(
        game,
        topology,
        'gp1',
        tileMapByRegion: tileMap,
        orderSuggestionApi: container.read(orderSuggestionApiProvider),
      );

      expect(fake.lastWorkTileMapByRegion, equals(tileMap));
    });

    test('gameEventBusProvider returns GameEventBus instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(gameEventBusProvider), isA<GameEventBus>());
    });
  });
}

final class _SpyOrderSuggestionAPI implements OrderSuggestionAPI {
  int suggestMoveCalls = 0;
  int suggestArmyMoveCalls = 0;
  Map<String, TileMapResult>? lastWorkTileMapByRegion;

  @override
  List<BuildUnitOrder> suggestBuildOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) =>
      const [];

  @override
  List<DiplomaticOrder> suggestDiplomaticOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) =>
      const [];

  @override
  List<MoveOrder> suggestMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) {
    suggestMoveCalls++;
    return const [];
  }

  @override
  List<ArmyMoveOrder> suggestArmyMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) {
    suggestArmyMoveCalls++;
    return const [];
  }

  @override
  List<NavalMissionOrder> suggestNavalMissionOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) =>
      const [];

  @override
  List<NavalMoveOrder> suggestNavalMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) =>
      const [];

  @override
  List<ResearchOrder> suggestResearchOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) =>
      const [];

  @override
  List<WorkOrder> suggestWorkOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    lastWorkTileMapByRegion = tileMapByRegion;
    return const [];
  }
}
