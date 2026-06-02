// Pins the Refs #2994 F7 contract for trade-order wiring inside
// `runDomainPlannersWithOutcome`:
//
//   - When the supplied [EconomyPlan.tradeOrders] is non-empty, the
//     orchestrator must merge the list into
//     `outcome.orders.tradeOrdersByPlayerId[nationId]` before returning,
//     so every caller (strategic-AI entry + the simpler
//     [runDomainPlanners] test entrypoint) surfaces the same trade
//     output without re-implementing the merge.
//   - The orchestrator must record `domainGateData.tradePlannerRan == true`
//     so the AI trace's `thresholds.domainGates.tradePlannerRan` flag
//     mirrors whether trade orders entered the merged Orders.
//   - When the supplied tradeOrders is empty, the orchestrator must NOT
//     add a `nationId` entry to `tradeOrdersByPlayerId` and must record
//     `tradePlannerRan == false` so downstream `MapEquality` checks see
//     a stable empty map for that player.
//   - Identical inputs across two orchestrator runs must produce
//     identical `tradeOrdersByPlayerId[nationId]` lists (determinism).
//
// The fixture reuses the minimal EXPAND game from
// `domain_planner_orchestrator_domain_gates_test.dart` so the new pin
// lives next to the existing gate-data contract instead of bringing up
// a heavier integration scenario.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/domain_planner_outcome.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';

const String _nationId = 'gp1';
const String _minorId = 'minor1';
const String _fieldArmyId = 'field_a';
const String _owMinorProvince = 'oldWorld|minor1';
const String _owHomeProvince = 'oldWorld|gp1_0';

const List<String> _gp1OwProvincesBelowQuota = <String>[
  _owHomeProvince,
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
];

Game _scenarioGame() {
  return Game(
    id: 'g-2994-f7-trade-wiring',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 30),
      oldWorld: RegionData(
        provinces: [
          for (final id in _gp1OwProvincesBelowQuota)
            Province(id: id, regionId: 'oldWorld', ownerId: _nationId),
          const Province(
            id: _owMinorProvince,
            regionId: 'oldWorld',
            ownerId: _minorId,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      armies: const [
        Army(
          id: _fieldArmyId,
          ownerId: _nationId,
          regionId: 'oldWorld',
          stationedProvinceId: _owHomeProvince,
          regimentUnitIds: ['u_field'],
          isHomeArmy: false,
        ),
      ],
    ),
    players: const [
      Player(
        id: _nationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'napoleon',
      ),
    ],
    minorNations: const [
      MinorNation(id: _minorId, displayName: 'Minor One'),
    ],
    tribes: const [],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _minorId,
        state: RelationState.atWar,
        score: -100,
      ),
    ],
  );
}

const FakeOrderSuggestionAPIForDomainPlannerTests _emptyApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
);

const AIConfig _aiConfig = AIConfig(
  leaderId: 'napoleon',
  personalityId: 'napoleon',
  hiddenAgendaId: 'warmonger',
);

AIWorldSnapshot _expandSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(atWarWith: [_minorId]),
    opportunities: OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 7,
      invadableProvinceIdsSorted: [_owMinorProvince],
      adjacentOwnerFactionIdsSorted: [_minorId],
    ),
    economy: EconomySummary(ownProvinceCount: 7),
    relations: {
      _minorId: DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _minorId,
        state: RelationState.atWar,
        score: -100,
      ),
    },
  );
}

DomainPlannerOutcome _runOrchestrator({required EconomyPlan economyPlan}) {
  final game = _scenarioGame();
  const topology = MapTopology(nodes: [], edges: []);
  final view = buildPlayerView(game, topology, _nationId);
  final snapshot = _expandSnapshot();
  return runDomainPlannersWithOutcome(
    game: game,
    topology: topology,
    nationId: _nationId,
    view: view,
    snapshot: snapshot,
    config: _aiConfig,
    primaryGoal: StrategicGoal.trade,
    seeds: AISeedBundle.fromTurnSeed(2994700),
    suggestionAPI: _emptyApi,
    economyPlan: economyPlan,
  );
}

void main() {
  group('Refs #2994 F7 — trade-order wiring in domain orchestrator', () {
    test(
      'non-empty economyPlan.tradeOrders is merged into outcome.orders',
      () {
        final tradeOrders = <TradeOrder>[
          TradeOrder(
            commodityId: 'timber',
            type: TradeOrderType.offer,
            quantity: 12,
            priority: 2,
          ),
          TradeOrder(
            commodityId: 'fabric',
            type: TradeOrderType.bid,
            quantity: 5,
            priority: 1,
          ),
        ];
        final outcome = _runOrchestrator(
          economyPlan: EconomyPlan(
            productionAssignments: const [],
            cargoPreference: CargoPreference.none,
            tradeOrders: tradeOrders,
          ),
        );

        final merged =
            outcome.orders.tradeOrdersByPlayerId[_nationId];
        expect(merged, isNotNull);
        expect(merged!, hasLength(2));
        expect(merged[0].commodityId, 'timber');
        expect(merged[0].type, TradeOrderType.offer);
        expect(merged[0].quantity, 12);
        expect(merged[0].priority, 2);
        expect(merged[1].commodityId, 'fabric');
        expect(merged[1].type, TradeOrderType.bid);

        final gates = outcome.domainGateData;
        expect(gates, isNotNull);
        expect(gates!.tradePlannerRan, isTrue);
      },
    );

    test(
      'empty economyPlan.tradeOrders leaves tradeOrdersByPlayerId absent and tradePlannerRan false',
      () {
        final outcome = _runOrchestrator(
          economyPlan: const EconomyPlan(
            productionAssignments: [],
            cargoPreference: CargoPreference.none,
          ),
        );
        expect(
          outcome.orders.tradeOrdersByPlayerId.containsKey(_nationId),
          isFalse,
          reason:
              'Orchestrator must skip the trade append when economyPlan'
              '.tradeOrders is empty so existing MapEquality assertions '
              'over Orders stay stable.',
        );
        final gates = outcome.domainGateData;
        expect(gates, isNotNull);
        expect(gates!.tradePlannerRan, isFalse);
      },
    );

    test(
      'identical inputs produce identical merged trade orders (determinism)',
      () {
        final tradeOrders = <TradeOrder>[
          TradeOrder(
            commodityId: 'iron',
            type: TradeOrderType.offer,
            quantity: 7,
            priority: 3,
          ),
        ];
        final plan = EconomyPlan(
          productionAssignments: const [],
          cargoPreference: CargoPreference.none,
          tradeOrders: tradeOrders,
        );
        final firstRun = _runOrchestrator(economyPlan: plan);
        final secondRun = _runOrchestrator(economyPlan: plan);

        final firstTrade =
            firstRun.orders.tradeOrdersByPlayerId[_nationId]!;
        final secondTrade =
            secondRun.orders.tradeOrdersByPlayerId[_nationId]!;
        expect(firstTrade, hasLength(secondTrade.length));
        for (var i = 0; i < firstTrade.length; i++) {
          expect(firstTrade[i].commodityId, secondTrade[i].commodityId);
          expect(firstTrade[i].type, secondTrade[i].type);
          expect(firstTrade[i].quantity, secondTrade[i].quantity);
          expect(firstTrade[i].priority, secondTrade[i].priority);
        }
        final firstGates = firstRun.domainGateData;
        final secondGates = secondRun.domainGateData;
        expect(firstGates, isNotNull);
        expect(secondGates, isNotNull);
        expect(firstGates!.tradePlannerRan, secondGates!.tradePlannerRan);
      },
    );
  });
}
