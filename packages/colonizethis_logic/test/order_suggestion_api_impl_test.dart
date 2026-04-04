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
                locationProvinceId: '$ow|p1',
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
      final affordableShipTreasury =
          ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost;
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
            workerPool: const WorkerPool(peasants: 1),
            treasury: affordableShipTreasury,
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
    test(
      'returns alliance (single diplo per target) for other GP when at peace and not allied',
      () {
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
      final toGp2 = list.where((o) => o.targetFactionId == 'gp2').toList();
      expect(toGp2, hasLength(1));
      expect(toGp2.single.type, DiplomaticOrderType.alliance);
    });

    test('returns declareWar toward GP when at peace and already allied', () {
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
            level: RelationLevel.allied,
          ),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(view, game, topology, const Orders());
      final toGp2 = list.where((o) => o.targetFactionId == 'gp2').toList();
      expect(toGp2, hasLength(1));
      expect(toGp2.single.type, DiplomaticOrderType.declareWar);
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
          oldWorld: RegionData(
            provinces: [
              // Add a province owned by the minor nation so it's "known" to gp1
              // through visibility (PR #1115: align suggestions with discovery visibility)
              Province(id: 'oldWorld|m1', regionId: 'oldWorld', ownerId: 'minor1'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {
              // Visibility for a tile in the minor's province makes it "known"
              'oldWorld|m1|0|0': 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            'oldWorld': {'oldWorld|m1': ['oldWorld|m1|0|0']},
          },
        ),
        players: [
          const Player(id: 'gp1', displayName: 'A', isHuman: false)
              .copyWith(
            treasury: 600,
            techUnlocked: const {'diplomatic_expertise': true},
          ),
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

    test(
      'toward minor at peace with join-empire overture suggests declareWar (primary before economic)',
      () {
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
              .copyWith(treasury: 5000),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            state: RelationState.atPeace,
            level: RelationLevel.neutral,
          ),
        ],
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.joinEmpire,
            sinceTurn: 0,
          ),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(view, game, topology, const Orders());
      final toMinor1 = list.where((o) => o.targetFactionId == 'minor1').toList();
      expect(toMinor1, hasLength(1));
      expect(toMinor1.single.type, DiplomaticOrderType.declareWar);
    });

    test('does not suggest toward target already in draft diplomatic orders', () {
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
      final withPending = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': [
            const DiplomaticOrder(
              type: DiplomaticOrderType.alliance,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );
      final list = api.suggestDiplomaticOrders(view, game, topology, withPending);
      expect(list.where((o) => o.targetFactionId == 'gp2'), isEmpty);
    });

    test('suggestDiplomaticOrders: cumulative list appendable and validates', () {
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
            level: RelationLevel.allied,
          ),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final suggestions =
          api.suggestDiplomaticOrders(view, game, topology, const Orders());
      final byTarget = <String, List<DiplomaticOrderType>>{};
      for (final o in suggestions) {
        byTarget.putIfAbsent(o.targetFactionId, () => []).add(o.type);
      }
      for (final e in byTarget.entries) {
        final types = e.value;
        expect(types.toSet().length, types.length,
            reason: 'at most one suggestion per type per target ${e.key}');
        final nonEconomic = types
            .where(
              (t) =>
                  t != DiplomaticOrderType.grantAid &&
                  t != DiplomaticOrderType.setSubsidy,
            )
            .length;
        expect(nonEconomic, lessThanOrEqualTo(1),
            reason: 'at most one primary diplomatic suggestion per target ${e.key}');
      }
      final eng = OrderEngine();
      for (final o in suggestions) {
        final addResult = eng.addDiplomaticOrderWithContext(
          game,
          topology,
          'gp1',
          o,
        );
        expect(addResult.isAccepted, isTrue,
            reason: '${o.type} ${o.targetFactionId} after prior suggestions');
      }
      final validateResults =
          eng.validatePlayerOrdersWithContext(game, topology, 'gp1');
      expect(validateResults, isNotEmpty);
      expect(
        validateResults.every((r) => r.isAccepted),
        isTrue,
        reason: 'full merged diplomatic list validates',
      );
    });

    test('removing pending diplomatic order restores suggestions for that target', () {
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
      final pending = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': [
            const DiplomaticOrder(
              type: DiplomaticOrderType.alliance,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );
      expect(
        api.suggestDiplomaticOrders(view, game, topology, pending)
            .where((o) => o.targetFactionId == 'gp2'),
        isEmpty,
      );
      final afterClear = api.suggestDiplomaticOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(
        afterClear.where((o) => o.targetFactionId == 'gp2'),
        isNotEmpty,
      );
    });
  });
}
