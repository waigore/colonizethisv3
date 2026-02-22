import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('DefaultOrderSuggestionAPI', () {
    late Game game;
    late MapTopology topology;
    late PlayerView view;
    late Orders emptyOrders;

    setUp(() {
      const ow = 'oldWorld';
      topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 'p2'),
        ],
      );
      game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              Province(id: '$ow|p2', regionId: ow, displayName: 'P2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'inf',
                ownerId: 'gp1',
                provinceId: '$ow|p1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {
              'oldWorld|p1|0|0': 'fullyVisible',
              'oldWorld|p2|0|0': 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            ow: {'$ow|p1': ['oldWorld|p1|0|0'], '$ow|p2': ['oldWorld|p2|0|0']},
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: true),
        ],
      );
      view = buildPlayerView(game, topology, 'gp1');
      emptyOrders = const Orders();
    });

    test('suggestMoveOrders returns list', () {
      const api = DefaultOrderSuggestionAPI();
      final list = api.suggestMoveOrders(view, game, topology, emptyOrders);
      expect(list, isA<List<MoveOrder>>());
    });

    test('suggestWorkOrders returns list', () {
      const api = DefaultOrderSuggestionAPI();
      final list = api.suggestWorkOrders(view, game, topology, emptyOrders);
      expect(list, isA<List<WorkOrder>>());
    });

    test('suggestBuildOrders returns list', () {
      const api = DefaultOrderSuggestionAPI();
      final list = api.suggestBuildOrders(view, game, topology, emptyOrders);
      expect(list, isA<List<BuildUnitOrder>>());
    });

    test('suggestResearchOrders returns list', () {
      const api = DefaultOrderSuggestionAPI();
      final list = api.suggestResearchOrders(view, game, topology, emptyOrders);
      expect(list, isA<List<ResearchOrder>>());
    });

    test('suggestNavalMoveOrders returns list', () {
      const api = DefaultOrderSuggestionAPI();
      final list = api.suggestNavalMoveOrders(view, game, topology, emptyOrders);
      expect(list, isA<List<NavalMoveOrder>>());
    });

    test('suggestNavalMissionOrders returns list', () {
      const api = DefaultOrderSuggestionAPI();
      final list = api.suggestNavalMissionOrders(view, game, topology, emptyOrders);
      expect(list, isA<List<NavalMissionOrder>>());
    });

    test('suggestDiplomaticOrders returns list', () {
      const api = DefaultOrderSuggestionAPI();
      final list = api.suggestDiplomaticOrders(view, game, topology, emptyOrders);
      expect(list, isA<List<DiplomaticOrder>>());
    });
  });

  group('suggestDiplomaticOrders', () {
    test('returns declareWar candidates for other GPs when at peace', () {
      const api = DefaultOrderSuggestionAPI();
      const topology = MapTopology(nodes: [], edges: []);
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(view, game, topology, const Orders());
      final declareWar = list.where((o) => o.type == DiplomaticOrderType.declareWar).toList();
      expect(declareWar.any((o) => o.targetFactionId == 'gp2'), isTrue);
    });
  });
}
