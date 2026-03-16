import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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

    test('suggestBuildOrders includes ship types when player can afford a ship', () {
      const api = DefaultOrderSuggestionAPI();
      const ow = 'oldWorld';
      final stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.lumber.id, 2)
          .applyDelta(CommodityCatalog.fabric.id, 2);
      final gameWithShip = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1')],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            capitalProvinceId: '$ow|p1',
            treasury: 100,
            stockpile: stockpile,
          ),
        ],
      );
      final topo = MapTopology(
        nodes: const [TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province)],
        edges: const [],
      );
      final v = buildPlayerView(gameWithShip, topo, 'gp1');
      final list = api.suggestBuildOrders(v, gameWithShip, topo, emptyOrders);
      final shipBuilds = list.where((o) => ShipEconomyCatalog.byId.containsKey(o.unitType)).toList();
      expect(shipBuilds, isNotEmpty, reason: 'API should suggest ship builds when affordable');
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
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            state: RelationState.atPeace,
            level: RelationLevel.neutral,
          ),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(view, game, topology, const Orders());
      final declareWar = list.where((o) => o.type == DiplomaticOrderType.declareWar).toList();
      expect(declareWar.any((o) => o.targetFactionId == 'gp2'), isTrue);
    });

    test('does not suggest diplomatic orders for completely unknown factions', () {
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
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list =
          api.suggestDiplomaticOrders(view, game, topology, const Orders());
      expect(
        list.any((o) => o.targetFactionId == 'minor1'),
        isFalse,
      );
    });

    test('returns offerPeace when at war with another GP', () {
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
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            state: RelationState.atWar,
            level: RelationLevel.hostile,
          ),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(view, game, topology, const Orders());
      final offerPeace = list.where((o) => o.type == DiplomaticOrderType.offerPeace).toList();
      expect(offerPeace.any((o) => o.targetFactionId == 'gp2'), isTrue);
    });

    test('returns alliance candidate when at peace and not allied', () {
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
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            state: RelationState.atPeace,
            level: RelationLevel.friendly,
          ),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(view, game, topology, const Orders());
      final alliance = list.where((o) => o.type == DiplomaticOrderType.alliance).toList();
      expect(alliance.any((o) => o.targetFactionId == 'gp2'), isTrue);
    });

    test('returns establishOverture for minor when treasury suffices', () {
      const api = DefaultOrderSuggestionAPI();
      const topology = MapTopology(nodes: [], edges: []);
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          const Player(id: 'gp1', displayName: 'A', isHuman: false)
              .copyWith(treasury: 600),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(view, game, topology, const Orders());
      final overture = list
          .where((o) => o.type == DiplomaticOrderType.establishOverture)
          .toList();
      expect(overture.any((o) => o.targetFactionId == 'minor1'), isTrue);
      expect(
        overture.any((o) =>
            o.targetFactionId == 'minor1' && o.overtureStage == OvertureStage.tradeConsulate),
        isTrue,
      );
    });

    test('returns grantAid and setSubsidy when overture has embassy and treasury >= 100', () {
      const api = DefaultOrderSuggestionAPI();
      const topology = MapTopology(nodes: [], edges: []);
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          const Player(id: 'gp1', displayName: 'A', isHuman: false)
              .copyWith(treasury: 200),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(view, game, topology, const Orders());
      final grantAid = list.where((o) => o.type == DiplomaticOrderType.grantAid).toList();
      final setSubsidy = list.where((o) => o.type == DiplomaticOrderType.setSubsidy).toList();
      expect(grantAid.any((o) => o.targetFactionId == 'minor1' && o.amount == 100), isTrue);
      expect(setSubsidy.any((o) => o.targetFactionId == 'minor1' && o.amount == 100), isTrue);
    });
  });
}
