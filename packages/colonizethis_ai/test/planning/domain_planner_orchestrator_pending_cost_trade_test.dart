// Pins the Refs #3122 orchestrator wiring for the
// `recomputeTradeOrdersWithPendingCosts` flag on
// `runDomainPlannersWithOutcome`:
//
//   - When set to `true`, the orchestrator MUST recompute trade
//     orders at the tail of the domain pipeline via
//     `runTreasuryPlanner(..., currentOrders: ctx.orders)` and merge
//     those orders into `outcome.orders.tradeOrdersByPlayerId[nationId]`.
//     `economyPlan.tradeOrders` is ignored in this mode.
//   - The recomputed trade orders MUST reflect pending treasury
//     costs from build / recruit / research orders that earlier
//     domain planners appended to `ctx.orders` — the bid budget
//     equals `max(0, treasury - pendingTreasuryCostsForTurn(...)
//     - carryForwardBidNotional(...))`, mirroring the matcher-side
//     per-buyer clamp introduced by #3115.
//   - When the flag is `false` (existing F7 contract) the
//     orchestrator MUST continue to consume `economyPlan.tradeOrders`
//     verbatim so prior behaviour stays preserved.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/domain_planner_outcome.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../domain_planner_test_fake_api.dart';

const String _nationId = 'gp1';
const String _minorId = 'minor1';
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

const _embassyOverture = OvertureState(
  gpId: _nationId,
  targetId: _minorId,
  stage: OvertureStage.embassy,
  sinceTurn: 0,
);

/// Builds an EXPAND below-quota scenario where:
/// - gp1 owns 7 OW provinces with a single invadable minor (forces
///   `needRegimentsToExpand` because `regimentCount == 0`).
/// - gp1's home army has no regiment unit ids so `regimentCount == 0`
///   and `forceRegimentRebuild` triggers in `_appendEconomyBuildOrders`.
/// - gp1's treasury is well above the cheapest regiment build cost so
///   the build planner can actually pick a regiment.
/// - WorldMarketState has integer prices so the treasury planner's
///   per-bid clamp resolves a non-null effective price for fabric.
Game _scenarioGame({
  required int treasury,
  required Stockpile stockpile,
}) {
  return Game(
    id: 'g-3122-orchestrator-pending-cost',
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
        // Empty regiment ids → regimentCount == 0 →
        // forceRegimentRebuild fires under expand quota pressure.
        Army(
          id: 'home_a',
          ownerId: _nationId,
          regionId: 'oldWorld',
          stationedProvinceId: _owHomeProvince,
          regimentUnitIds: <String>[],
          isHomeArmy: true,
        ),
      ],
    ),
    players: [
      Player(
        id: _nationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'napoleon',
        capitalProvinceId: _owHomeProvince,
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 5),
        treasury: treasury,
      ),
    ],
    minorNations: const [
      MinorNation(id: _minorId, displayName: 'Minor One'),
    ],
    overtureStates: const [_embassyOverture],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _minorId,
        state: RelationState.atWar,
        score: -100,
      ),
    ],
    worldMarketState: WorldMarketState.withDefaultPrices(const {
      'timber': 20,
      'iron': 20,
      // Fabric price (10) is strictly below the recipe's input cost
      // when valued at the wool price (50), so the F3 price gate in
      // `runTreasuryPlanner` admits a fabric bid for the deficit.
      'fabric': 10,
      'wool': 50,
      'cotton': 50,
    }),
  );
}

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

DomainPlannerOutcome _runOrchestrator({
  required EconomyPlan economyPlan,
  required Game game,
  required FakeOrderSuggestionAPIForDomainPlannerTests api,
  required bool recompute,
}) {
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
    primaryGoal: StrategicGoal.expand,
    seeds: AISeedBundle.fromTurnSeed(3122700),
    suggestionAPI: api,
    economyPlan: economyPlan,
    recomputeTradeOrdersWithPendingCosts: recompute,
  );
}

void main() {
  group(
    'Refs #3122 — orchestrator trade-order recompute with pending costs',
    () {
      test(
        'when the flag is set, the orchestrator picks a peasant_levies '
        'regiment build and the recomputed trade-order bid budget '
        'subtracts that pending treasury cost',
        () {
          // Fabric deficit driver: wool=4 + fabric_from_wool recipe.
          // Stockpile fabric=1 satisfies the regiment build input
          // affordability gate so the build planner accepts the
          // candidate.
          final stockpile = const Stockpile()
              .applyDelta('wool', 4)
              .applyDelta('fabric', 1);
          final game = _scenarioGame(treasury: 4000, stockpile: stockpile);
          const peasantBuild = BuildUnitOrder(
            unitType: 'peasant_levies',
            isMilitary: true,
            spawnProvinceId: _owHomeProvince,
          );
          const api = FakeOrderSuggestionAPIForDomainPlannerTests(
            work: [],
            build: [peasantBuild],
            move: [],
            research: [],
            navalMove: [],
            navalMission: [],
          );
          final outcome = _runOrchestrator(
            economyPlan: const EconomyPlan(
              productionAssignments: [
                AssignedRecipe(
                  recipeId: 'fabric_from_wool',
                  assignedLabour: 4,
                ),
              ],
              cargoPreference: CargoPreference.none,
              tradeOrders: <TradeOrder>[],
            ),
            game: game,
            api: api,
            recompute: true,
          );
          // The orchestrator's build pass must have appended the
          // peasant_levies candidate so the pending-cost projector
          // sees `buildTreasuryCost == 2000`.
          final builds =
              outcome.orders.buildUnitOrdersByPlayerId[_nationId];
          expect(builds, isNotNull);
          expect(builds!, hasLength(1));
          expect(builds.first.unitType, 'peasant_levies');

          // The recomputed trade orders must respect the budget
          // invariant: cumulative bid notional <= treasury - pending
          // build cost.
          const cheapestRegimentBuildTreasuryCost = 2000;
          final trades =
              outcome.orders.tradeOrdersByPlayerId[_nationId] ?? const [];
          final bidNotional = trades
              .where((o) => o.type == TradeOrderType.bid)
              .fold<int>(
                0,
                (sum, b) =>
                    sum +
                    b.quantity *
                        (game.worldMarketState.prices[b.commodityId] ?? 0)
                            .toInt(),
              );
          expect(
            bidNotional,
            lessThanOrEqualTo(4000 - cheapestRegimentBuildTreasuryCost),
            reason: 'Pending peasant_levies build (treasuryCost 2000) must '
                'reduce the recomputed trade-order bid budget below the '
                'remaining treasury of 2000.',
          );
          // The recompute path also flips tradePlannerRan exactly when
          // it produced any orders, mirroring the F7 wiring contract.
          expect(
            outcome.domainGateData?.tradePlannerRan,
            trades.isNotEmpty,
          );
        },
      );

      test(
        'when the flag is set, mock economyPlan.tradeOrders are ignored '
        'and the orchestrator emits its own recomputed list',
        () {
          // Mock trade orders that have no relation to the actual game
          // state: a fabricated grain bid at quantity 99. The flag
          // requires the orchestrator to discard this and recompute.
          final mockTrade = <TradeOrder>[
            TradeOrder(
              commodityId: 'grain',
              type: TradeOrderType.bid,
              quantity: 99,
              priority: 1,
            ),
          ];
          // Tiny treasury so no bid budget remains for any commodity;
          // every recomputed bid is clamped to zero and the recomputed
          // list cannot equal the mock list.
          final game = _scenarioGame(
            treasury: 0,
            stockpile: const Stockpile().applyDelta('timber', 80),
          );
          const api = FakeOrderSuggestionAPIForDomainPlannerTests(
            work: [],
            build: [],
            move: [],
            research: [],
            navalMove: [],
            navalMission: [],
          );
          final outcome = _runOrchestrator(
            economyPlan: EconomyPlan(
              productionAssignments: const [],
              cargoPreference: CargoPreference.none,
              tradeOrders: mockTrade,
            ),
            game: game,
            api: api,
            recompute: true,
          );
          final trades =
              outcome.orders.tradeOrdersByPlayerId[_nationId] ?? const [];
          // The mock 99-quantity grain bid must not survive a recompute
          // pass that runs with `treasury == 0` (per-bid clamp drops
          // every priced bid).
          final survivedMock = trades.any(
            (o) =>
                o.commodityId == 'grain' &&
                o.type == TradeOrderType.bid &&
                o.quantity == 99,
          );
          expect(
            survivedMock,
            isFalse,
            reason:
                'recomputeTradeOrdersWithPendingCosts: true must ignore '
                'economyPlan.tradeOrders and call runTreasuryPlanner '
                'directly.',
          );
        },
      );

      test(
        'when the flag is unset (default), mock economyPlan.tradeOrders '
        'still flow through unchanged (existing F7 wiring contract)',
        () {
          final mockTrade = <TradeOrder>[
            TradeOrder(
              commodityId: 'fabric',
              type: TradeOrderType.offer,
              quantity: 3,
              priority: 5,
            ),
          ];
          final game = _scenarioGame(
            treasury: 0,
            stockpile: const Stockpile(),
          );
          const api = FakeOrderSuggestionAPIForDomainPlannerTests(
            work: [],
            build: [],
            move: [],
            research: [],
            navalMove: [],
            navalMission: [],
          );
          final outcome = _runOrchestrator(
            economyPlan: EconomyPlan(
              productionAssignments: const [],
              cargoPreference: CargoPreference.none,
              tradeOrders: mockTrade,
            ),
            game: game,
            api: api,
            recompute: false,
          );
          final trades =
              outcome.orders.tradeOrdersByPlayerId[_nationId];
          expect(trades, isNotNull);
          expect(trades, hasLength(1));
          expect(trades!.first.commodityId, 'fabric');
          expect(trades.first.type, TradeOrderType.offer);
          expect(trades.first.quantity, 3);
        },
      );
    },
  );
}
