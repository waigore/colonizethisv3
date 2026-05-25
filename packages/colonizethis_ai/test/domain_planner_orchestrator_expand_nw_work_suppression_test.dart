// Pins the EXPAND-phase New World work-order suppression AC from issue #2509:
//
//   Given a GP in EXPAND with sea-reachable unowned NW provinces, when domain
//   planning runs, then no NW declareWar, NW army move, or NW purchase_land
//   orders are suggested that turn.
//
// This test pins the **civilian work** and **conquest army move** portions of
// that contract at the `runDomainPlanners` integration boundary. The
// orchestrator must drop NW `purchase_land`, NW `build_improvement`, and NW
// invasion `ArmyMoveOrder` suggestions while in EXPAND
// (`shouldFilterObserverPhaseWorkOrder` for `ObserverGoalPhase.expand`).
//
// Existing tests pin the underlying predicate
// (`packages/colonizethis_ai/test/observer_goal_phase_test.dart` group
// `shouldFilterObserverPhaseWorkOrder`) and the selection priority among
// already-suggested work orders
// (`packages/colonizethis_logic/test/full_ai_civilian_work_selection_colonial_test.dart`).
// Neither pins the **integration** that the orchestrator actually applies the
// EXPAND filter when merging civilian work into `runDomainPlanners` output —
// a tuning change that left the predicate intact but bypassed the filter
// call would silently emit NW work orders while below quota.
//
// The negative control asserts a GP at quota with visible colonial targets
// (`ObserverGoalPhase.colonial`) does not drop the same NW work orders, so a
// regression that over-suppresses NW work in COLONIAL is also caught.
//
// SPEC:
//   - `SPEC/ai/ai-architecture.md` § Observer goal phases (Full AI)
//   - `SPEC/program/order-suggestions.md` § Work orders (visibility)

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';

const String _nationId = 'gp1';
const String _fieldArmyId = 'field_a';
const String _owProvince = 'oldWorld|home';
const String _owMinorProvince = 'oldWorld|minor1';
const String _nwOwnedProvince = 'newWorld|owned';
const String _nwTribeProvince = 'newWorld|tribe';
const String _owTile = '$_owProvince|0|0';
const String _nwOwnedTile = '$_nwOwnedProvince|0|0';
const String _nwTribeTile = '$_nwTribeProvince|0|0';

/// Builds a game with one OW Builder, one NW Builder (in a GP-owned NW
/// province), and one NW Merchant (in a tribe-owned NW province). Each unit
/// sits on a deterministic tile so the candidate keys in the fake suggestion
/// API resolve unambiguously. Phase selection is driven entirely by the
/// snapshot the caller passes to `runDomainPlanners`.
Game _expandScenarioGame() {
  return Game(
    id: 'g-2509-expand-nw-suppress',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 10),
      oldWorld: RegionData(
        provinces: const [
          Province(id: _owProvince, regionId: 'oldWorld', ownerId: _nationId),
          Province(
            id: _owMinorProvince,
            regionId: 'oldWorld',
            ownerId: 'minor1',
          ),
        ],
        units: [
          Unit(
            id: 'b_ow',
            type: kUnitTypeBuilder,
            ownerId: _nationId,
            locationProvinceId: _owProvince,
            tileKey: _owTile,
          ),
        ],
      ),
      newWorld: RegionData(
        provinces: const [
          Province(
            id: _nwOwnedProvince,
            regionId: 'newWorld',
            ownerId: _nationId,
          ),
          Province(
            id: _nwTribeProvince,
            regionId: 'newWorld',
            ownerId: 'tribe1',
          ),
        ],
        units: [
          Unit(
            id: 'b_nw',
            type: kUnitTypeBuilder,
            ownerId: _nationId,
            locationProvinceId: _nwOwnedProvince,
            tileKey: _nwOwnedTile,
          ),
          Unit(
            id: 'm_nw',
            type: kUnitTypeMerchant,
            ownerId: _nationId,
            locationProvinceId: _nwTribeProvince,
            tileKey: _nwTribeTile,
          ),
        ],
      ),
      armies: const [
        Army(
          id: _fieldArmyId,
          ownerId: _nationId,
          regionId: 'oldWorld',
          stationedProvinceId: _owProvince,
          regimentUnitIds: [],
          isHomeArmy: false,
        ),
      ],
      playerVisibilityByTile: const {
        _nationId: {
          _owTile: 'fullyVisible',
          _nwOwnedTile: 'fullyVisible',
          _nwTribeTile: 'fullyVisible',
        },
      },
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          _owProvince: [_owTile],
        },
        'newWorld': {
          _nwOwnedProvince: [_nwOwnedTile],
          _nwTribeProvince: [_nwTribeTile],
        },
      },
      resourceByTileKey: const {
        _owTile: 'grain',
        _nwOwnedTile: 'grain',
        _nwTribeTile: 'grain',
      },
    ),
    players: const [
      Player(
        id: _nationId,
        displayName: 'GP',
        isHuman: false,
        leaderKey: 'victoria',
      ),
    ],
    tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: _nationId,
        factionId2: 'tribe1',
        state: RelationState.atWar,
        score: 10,
      ),
      DiplomacyRelation(
        factionId1: _nationId,
        factionId2: 'minor1',
        state: RelationState.atWar,
        score: 10,
      ),
    ],
  );
}

const FakeOrderSuggestionAPIForDomainPlannerTests _mixedRegionWorkApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
      work: [
        WorkOrder(
          unitId: 'b_ow',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _owTile,
        ),
        WorkOrder(
          unitId: 'b_nw',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _nwOwnedTile,
        ),
        WorkOrder(
          unitId: 'm_nw',
          target: kWorkTargetPurchaseLand,
          targetTileKey: _nwTribeTile,
        ),
      ],
      build: [],
      move: [],
      research: [],
      navalMove: [],
      navalMission: [],
    );

const FakeOrderSuggestionAPIForDomainPlannerTests _mixedOwNwArmyMoveApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
      work: [],
      build: [],
      move: [],
      research: [],
      navalMove: [],
      navalMission: [],
      armyMove: [
        ArmyMoveOrder(
          armyId: _fieldArmyId,
          destinationProvinceId: _nwTribeProvince,
        ),
        ArmyMoveOrder(
          armyId: _fieldArmyId,
          destinationProvinceId: _owMinorProvince,
        ),
      ],
    );

const FakeOrderSuggestionAPIForDomainPlannerTests _nwOnlyArmyMoveApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
      work: [],
      build: [],
      move: [],
      research: [],
      navalMove: [],
      navalMission: [],
      armyMove: [
        ArmyMoveOrder(
          armyId: _fieldArmyId,
          destinationProvinceId: _nwTribeProvince,
        ),
      ],
    );

const EconomyPlan _economyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig _aiConfig = AIConfig(
  leaderId: 'victoria',
  personalityId: 'victoria',
  hiddenAgendaId: 'peacemaker',
);

void main() {
  group('runDomainPlanners EXPAND-phase NW work suppression', () {
    test(
      'EXPAND drops NW build_improvement and NW purchase_land, keeps OW build_improvement',
      () {
        final game = _expandScenarioGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = AIWorldSnapshot(
          playerId: _nationId,
          threats: const ThreatSummary(),
          opportunities: const OpportunitySummary(),
          conquest: const ConquestSummary(oldWorldProvincesOwned: 7),
          colonial: const ColonialSummary(
            invadableNewWorldProvinceIdsSorted: [_nwTribeProvince],
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          economy: const EconomySummary(ownProvinceCount: 1),
          relations: const {},
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
          reason:
              'Fixture must place GP in EXPAND so the suppression contract '
              'is exercised, not the COLONIAL fall-through.',
        );

        final orders = runDomainPlanners(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(2509001),
          suggestionAPI: _mixedRegionWorkApi,
          economyPlan: _economyPlan,
        );

        final work = orders.workOrdersByPlayerId[_nationId] ?? const [];
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetBuildImprovement &&
                w.targetTileKey == _nwOwnedTile,
          ),
          isFalse,
          reason: 'EXPAND must drop NW build_improvement candidates.',
        );
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetPurchaseLand &&
                w.targetTileKey == _nwTribeTile,
          ),
          isFalse,
          reason: 'EXPAND must drop NW purchase_land candidates.',
        );
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetBuildImprovement &&
                w.targetTileKey == _owTile,
          ),
          isTrue,
          reason:
              'OW build_improvement is not a New World colonial order and must '
              'survive the EXPAND filter (control).',
        );
      },
    );

    test(
      'COLONIAL keeps the same NW work candidates the EXPAND filter would drop',
      () {
        final game = _expandScenarioGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = AIWorldSnapshot(
          playerId: _nationId,
          threats: const ThreatSummary(),
          opportunities: const OpportunitySummary(),
          conquest: const ConquestSummary(oldWorldProvincesOwned: 11),
          colonial: const ColonialSummary(
            newWorldProvincesOwned: 1,
            invadableNewWorldProvinceIdsSorted: [_nwTribeProvince],
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          economy: const EconomySummary(ownProvinceCount: 2),
          relations: const {},
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.colonial,
          reason:
              'Negative-control fixture must place GP in COLONIAL so the '
              'EXPAND filter is verified to **not** fire here.',
        );

        final orders = runDomainPlanners(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.diplomacy,
          seeds: AISeedBundle.fromTurnSeed(2509002),
          suggestionAPI: _mixedRegionWorkApi,
          economyPlan: _economyPlan,
        );

        final work = orders.workOrdersByPlayerId[_nationId] ?? const [];
        // selectFullAiCivilianWorkOrders may pick a single per-unit best
        // target, so we don't assert all three remain; the key contract is
        // that NW build_improvement / NW purchase_land are not unconditionally
        // suppressed (at least one survives the orchestrator's filter pass).
        expect(
          work.any(
            (w) =>
                (w.target == kWorkTargetBuildImprovement &&
                    w.targetTileKey == _nwOwnedTile) ||
                (w.target == kWorkTargetPurchaseLand &&
                    w.targetTileKey == _nwTribeTile),
          ),
          isTrue,
          reason:
              'COLONIAL must not apply the EXPAND NW work-order filter; at '
              'least one NW civilian work order must survive.',
        );
      },
    );

    test(
      'EXPAND conquest army move prefers OW invadable minor over NW tribe',
      () {
        final game = _expandScenarioGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = AIWorldSnapshot(
          playerId: _nationId,
          threats: const ThreatSummary(atWarWith: ['tribe1', 'minor1']),
          opportunities: const OpportunitySummary(),
          conquest: const ConquestSummary(
            oldWorldProvincesOwned: 7,
            invadableProvinceIdsSorted: [_owMinorProvince],
          ),
          colonial: const ColonialSummary(
            invadableNewWorldProvinceIdsSorted: [_nwTribeProvince],
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          economy: const EconomySummary(ownProvinceCount: 1),
          relations: const {},
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
        );

        final orders = runDomainPlanners(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(2509004),
          suggestionAPI: _mixedOwNwArmyMoveApi,
          economyPlan: _economyPlan,
        );

        final armyMoves =
            orders.armyMoveOrdersByPlayerId[_nationId] ?? const [];
        expect(armyMoves, isNotEmpty);
        expect(
          armyMoves.any((m) => m.destinationProvinceId == _nwTribeProvince),
          isFalse,
          reason:
              'When OW and NW army-move candidates are both suggested, EXPAND '
              'must score NW invasion to zero and prefer the OW invadable path.',
        );
        expect(
          armyMoves.any((m) => m.destinationProvinceId == _owMinorProvince),
          isTrue,
          reason: 'OW invadable minor must remain the chosen conquest move.',
        );
      },
    );

    test(
      'COLONIAL keeps NW army move the EXPAND conquest path would suppress',
      () {
        final game = _expandScenarioGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = AIWorldSnapshot(
          playerId: _nationId,
          threats: const ThreatSummary(atWarWith: ['tribe1']),
          opportunities: const OpportunitySummary(),
          conquest: const ConquestSummary(oldWorldProvincesOwned: 11),
          colonial: const ColonialSummary(
            newWorldProvincesOwned: 1,
            invadableNewWorldProvinceIdsSorted: [_nwTribeProvince],
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          economy: const EconomySummary(ownProvinceCount: 2),
          relations: const {},
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.colonial,
        );

        final orders = runDomainPlanners(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.conquer,
          seeds: AISeedBundle.fromTurnSeed(2509005),
          suggestionAPI: _nwOnlyArmyMoveApi,
          economyPlan: _economyPlan,
        );

        final armyMoves =
            orders.armyMoveOrdersByPlayerId[_nationId] ?? const [];
        expect(
          armyMoves.any((m) => m.destinationProvinceId == _nwTribeProvince),
          isTrue,
          reason:
              'COLONIAL must allow NW invasion army moves toward visible '
              'colonial targets.',
        );
      },
    );

    test('EXPAND filter outcome is deterministic for identical inputs', () {
      final game = _expandScenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = AIWorldSnapshot(
        playerId: _nationId,
        threats: const ThreatSummary(),
        opportunities: const OpportunitySummary(),
        conquest: const ConquestSummary(oldWorldProvincesOwned: 7),
        colonial: const ColonialSummary(
          invadableNewWorldProvinceIdsSorted: [_nwTribeProvince],
          adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
        ),
        economy: const EconomySummary(ownProvinceCount: 1),
        relations: const {},
      );
      final seeds = AISeedBundle.fromTurnSeed(2509003);

      final first = runDomainPlanners(
        game: game,
        topology: topology,
        nationId: _nationId,
        view: view,
        snapshot: snapshot,
        config: _aiConfig,
        primaryGoal: StrategicGoal.expand,
        seeds: seeds,
        suggestionAPI: _mixedRegionWorkApi,
        economyPlan: _economyPlan,
      );
      final second = runDomainPlanners(
        game: game,
        topology: topology,
        nationId: _nationId,
        view: view,
        snapshot: snapshot,
        config: _aiConfig,
        primaryGoal: StrategicGoal.expand,
        seeds: seeds,
        suggestionAPI: _mixedRegionWorkApi,
        economyPlan: _economyPlan,
      );

      List<String> describe(Orders orders) =>
          (orders.workOrdersByPlayerId[_nationId] ?? const [])
              .map((w) => '${w.unitId}|${w.target}|${w.targetTileKey}')
              .toList();
      expect(describe(first), describe(second));
    });
  });
}
