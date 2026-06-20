// Pins the EXPAND-phase forced GP-only invadable frontier blocker
// `declareWar` contract at the `runDomainPlanners` integration boundary
// (Refs #2509).
//
// `stalledGpBlockerDeclareWarTarget`
// (`packages/colonizethis_ai/lib/src/planning/diplomacy_planner.dart`)
// forces a declare-war target when invadable Old World is held only by
// Great Powers (no minor on the border) and the GP is still below the
// observer conquest quota / stalled in the 1–9 OW band. The helper is
// exhaustively pinned at the function level by
// `packages/colonizethis_ai/test/diplomatic_candidate_scoring_suppression_part2_test.dart`
// (`stalledGpBlockerDeclareWarTarget` group: GP-only invadable blocker
// positive, mutual-plateau skip, zero-regiment skip, already-at-war
// skip, …) and was added on `origin/dev` by issue #2509 PR
// [#2577](https://github.com/waigore/colonizethisv3/pull/2577)
// (`fix(ai): GP-only invadable frontier blocker declare priority`).
//
// Neither the helper-level tests nor the existing diplomacy-planner
// suppression tests run the orchestrator, so a future tuning slice
// could leave the predicate intact but silently bypass the orchestrator
// short-circuit that emits the forced `declareWar` (for example by
// narrowing the `if (isOldWorldGpOnlyInvadableFrontier(...))` guard
// around `_plateauGpBlockerDeclarePlannerResultIfNeeded` in
// `runDiplomacyPlannerWithResult`, or by reordering the minor-first
// declare passes so a fall-through never reaches the GP-only blocker
// branch). That regression would starve below-quota EXPAND GPs of the
// only winnable declare on a GP-only invadable frontier (seed-42
// gp3/gp4) and directly threaten the turn-100
// `--verify-conquest` per-GP ≥3 net OW gain gate the nightly observer
// pipeline enforces (`SPEC/program/run_observer_game-tool.md` § Turn
// 100 OW conquest verify; nightly job `observer_conquest_verify` on
// `origin/dev` via PR #2506).
//
// This file is the orchestrator-level counterpart to:
//   - `diplomatic_candidate_scoring_suppression_part2_test.dart` group
//     `stalledGpBlockerDeclareWarTarget` (helper-level), and
//   - `domain_planner_orchestrator_expand_minor_declare_war_test.dart`
//     (EXPAND adjacent invadable OW minor `declareWar` orchestrator
//     pin, sibling slice for #2509 — PR #2621) so the EXPAND
//     declare-war priority order
//     ((a) minor-first → (b) GP-only blocker → (c) stalled invadable
//     GP owner) stays side-by-side reviewable.
//
// SPEC:
//   - `SPEC/ai/ai-architecture.md` § Observer goal phases (Full AI),
//     EXPAND declare-war priority order (GP-only invadable frontier
//     blocker after minor-first declares).
//   - `SPEC/program/order-suggestions.md` § Diplomatic orders.
//
// Coverage layers:
//   - Positive: EXPAND-phase merged diplomatic orders contain
//     `declareWar` toward the GP blocker even when the suggestion API
//     surfaces no candidate (the forced short-circuit appends the
//     order directly to the planner result).
//   - Negative: at-quota DEVELOP-phase merged diplomatic orders do
//     **not** contain `declareWar` toward the same GP blocker — the
//     `stalledGpBlockerDeclareWarTarget` helper short-circuits at the
//     `!isBelowObserverConquestQuota && !isStalledOldWorldExpansion`
//     gate, the `_plateauGpBlockerDeclarePlannerResultIfNeeded`
//     wrapper additionally short-circuits at the same gate, and
//     DEVELOP scoring zeroes every declare-war candidate so the
//     non-forced scoring fall-through cannot resurrect the order
//     either. This catches a regression that would silently re-emit
//     the forced declare past the OW conquest quota and burn turns
//     that should be servicing the turn-150 70% improvement gate.
//   - Determinism guard: re-running with identical EXPAND inputs
//     produces an identical diplomatic-order fingerprint (must-have
//     #7).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';

const String _nationId = 'gp1';
const String _blockerGpId = 'gp2';

// Sub-quota OW set (< `kObserverConquestMinOwProvincesPerGp` = 10) and
// inside the stalled 1–9 band so `isBelowObserverConquestQuota` and
// `isStalledOldWorldExpansion` are both true and
// `observerGoalPhaseFor` routes to EXPAND. Sized at 7 (the observer
// default start) to mirror the seed-42 gp3/gp4 narrative the GP-only
// blocker priority was originally tuned for (PR #2577).
const List<String> _gp1OwProvincesBelowQuota = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
];

// Past-quota OW set (>= `kObserverConquestMinOwProvincesPerGp` = 10)
// and above the stalled 1–9 band so both
// `isBelowObserverConquestQuota` and `isStalledOldWorldExpansion`
// return false. Combined with an empty `ColonialSummary` it routes
// `observerGoalPhaseFor` into DEVELOP, where every declare-war
// candidate score collapses (verified in `observer_goal_phase_test.dart`
// group `DEVELOP suppresses declareWar`).
const List<String> _gp1OwProvincesDevelop = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
  'oldWorld|gp1_7',
  'oldWorld|gp1_8',
  'oldWorld|gp1_9',
  'oldWorld|gp1_10',
  'oldWorld|gp1_11',
];

// gp2 owns exactly the invadable provinces, so
// `primaryInvadableOldWorldGpBlocker` resolves to `_blockerGpId` and
// `isOldWorldGpOnlyInvadableFrontier` returns true. Province count of
// 4 is deliberately outside the mutual-plateau 8–9 OW band so
// `isMutualBelowQuotaPlateauPeer(ownOw=7, partnerOw=4)` is false and
// the helper does not bail on the plateau-peer skip (which is the
// branch the diplomatic_candidate_scoring_suppression_part2_test.dart
// `mutual plateau within one OW on GP-only` case pins separately).
const List<String> _blockerOwProvinces = <String>[
  'oldWorld|gp2_inv_0',
  'oldWorld|gp2_inv_1',
  'oldWorld|gp2_inv_2',
  'oldWorld|gp2_inv_3',
];

Game _scenarioGame({required List<String> gp1OwProvinces}) {
  return Game(
    id: 'g-2509-expand-gp-only-blocker',
    worldState: WorldState(
      // Turn 60 sits past `kDeclareWarEarlyAntiDogpileMaxTurn` = 50,
      // so the early-turn anti-dogpile gate inside
      // `stalledGpBlockerDeclareWarTarget` (which only fires when the
      // blocker is below quota AND the frontier is *not* GP-only) is
      // moot for this fixture, and the forced GP-only blocker declare
      // is exercised without turn-window confounders.
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
      oldWorld: RegionData(
        provinces: [
          for (final id in gp1OwProvinces)
            Province(id: id, regionId: 'oldWorld', ownerId: _nationId),
          for (final id in _blockerOwProvinces)
            Province(id: id, regionId: 'oldWorld', ownerId: _blockerGpId),
        ],
      ),
      newWorld: const RegionData(),
      // Non-empty Home Armies for both gp1 and gp2 keep
      // `regimentCountForPlayer` > 0 for the attacker (required by
      // `stalledGpBlockerDeclareWarTarget`) and for the blocker
      // (required for the mutual-plateau branch the helper guards
      // against, though it does not fire here per the fixture sizing
      // above). The same home-army guard is used in the sibling
      // EXPAND minor declare-war pin
      // (`domain_planner_orchestrator_expand_minor_declare_war_test.dart`)
      // and the two-GP peace pin
      // (`domain_planner_orchestrator_expand_two_gp_peace_test.dart`).
      armies: [
        Army(
          id: homeArmyIdFor(_nationId),
          ownerId: _nationId,
          regionId: 'oldWorld',
          stationedProvinceId: gp1OwProvinces.first,
          regimentUnitIds: const ['u_gp1'],
          isHomeArmy: true,
        ),
        Army(
          id: homeArmyIdFor(_blockerGpId),
          ownerId: _blockerGpId,
          regionId: 'oldWorld',
          stationedProvinceId: _blockerOwProvinces.first,
          regimentUnitIds: const ['u_gp2'],
          isHomeArmy: true,
        ),
      ],
    ),
    players: const [
      Player(
        id: _nationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'henry',
      ),
      Player(id: _blockerGpId, displayName: 'GP2', isHuman: false),
    ],
    // No minor nations: `hasUninvadedOldWorldMinor` returns false, no
    // minor declare-war target is available, and every minor-first
    // forced declare path in `runDiplomacyPlannerWithResult` falls
    // through to the GP-only blocker branch this test pins.
    minorNations: const [],
    tribes: const [],
  );
}

// Empty suggestion API: no diplomatic candidates are surfaced. The
// forced GP-only blocker short-circuit appends the `declareWar`
// directly to the planner result without going through the suggestion
// API, so an empty API isolates the orchestrator's forced-declare
// integration from any candidate scoring path.
const FakeOrderSuggestionAPIForDomainPlannerTests _emptyApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
);

const EconomyPlan _economyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

// `henry` / `merchant` matches the sibling EXPAND minor declare-war
// orchestrator pin in
// `domain_planner_orchestrator_expand_minor_declare_war_test.dart`.
// The `peacemaker` agenda would zero declare-war candidates regardless
// of phase via the agenda conquer modifier and risk masking the
// forced-blocker emission contract.
const AIConfig _aiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

AIWorldSnapshot _expandSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    // 7 OW provinces -> EXPAND (`isBelowObserverConquestQuota` true,
    // observer goal phase routes to EXPAND). The invadable list lists
    // only `_blockerGpId`-owned provinces so
    // `primaryInvadableOldWorldGpBlocker` resolves to `_blockerGpId`
    // and `isOldWorldGpOnlyInvadableFrontier` is true. The blocker
    // also appears in `adjacentOwnerFactionIdsSorted` because that is
    // how the perception layer surfaces a sole GP frontier neighbor
    // (mirrors the helper-level fixture in
    // `diplomatic_candidate_scoring_suppression_part2_test.dart`
    // group `stalledGpBlockerDeclareWarTarget returns GP-only invadable
    // blocker`).
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 7,
      provincesToVictory: 24,
      invadableProvinceIdsSorted: <String>[
        'oldWorld|gp2_inv_0',
        'oldWorld|gp2_inv_1',
        'oldWorld|gp2_inv_2',
        'oldWorld|gp2_inv_3',
      ],
      adjacentOwnerFactionIdsSorted: <String>[_blockerGpId],
    ),
    colonial: ColonialSummary(),
    economy: EconomySummary(ownProvinceCount: 7),
    relations: {},
  );
}

AIWorldSnapshot _developSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    // 12 OW provinces past the observer quota with no colonial
    // acquisition targets: `observerGoalPhaseFor` routes to DEVELOP.
    // Both `isBelowObserverConquestQuota(12)` and
    // `isStalledOldWorldExpansion(12)` are false, so the helper
    // `stalledGpBlockerDeclareWarTarget` short-circuits at its
    // observer-quota / stalled-OW gate and the
    // `_plateauGpBlockerDeclarePlannerResultIfNeeded` wrapper
    // additionally short-circuits at the same gate.
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 12,
      provincesToVictory: 19,
      invadableProvinceIdsSorted: <String>[
        'oldWorld|gp2_inv_0',
        'oldWorld|gp2_inv_1',
        'oldWorld|gp2_inv_2',
        'oldWorld|gp2_inv_3',
      ],
      adjacentOwnerFactionIdsSorted: <String>[_blockerGpId],
    ),
    colonial: ColonialSummary(),
    economy: EconomySummary(ownProvinceCount: 12),
    relations: {},
  );
}

List<String> _declareWarTargets(Orders orders) => <String>[
  for (final order in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
    if (order.type == DiplomaticOrderType.declareWar) order.targetFactionId,
];

void main() {
  group('runDomainPlanners EXPAND GP-only blocker declareWar', () {
    test(
      'emits forced declareWar toward GP-only invadable frontier blocker in EXPAND',
      () {
        final game = _scenarioGame(gp1OwProvinces: _gp1OwProvincesBelowQuota);
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _expandSnapshot();

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
          reason:
              'Fixture must place GP in EXPAND so the GP-only invadable '
              'frontier blocker forced declare-war path is exercised by '
              'the orchestrator (not the COLONIAL/DEVELOP fall-through, '
              'which gates `_plateauGpBlockerDeclarePlannerResultIfNeeded` '
              'off at `!isBelowObserverConquestQuota` per SPEC § Observer '
              'goal phases (Full AI) EXPAND declare-war priority order).',
        );

        final orders = runDomainPlanners(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(2509121),
          suggestionAPI: _emptyApi,
          economyPlan: _economyPlan,
        );

        expect(
          _declareWarTargets(orders),
          contains(_blockerGpId),
          reason:
              'EXPAND below quota with a GP-only invadable Old World '
              'frontier (no minor on the border) must surface the forced '
              '`declareWar` toward the primary invadable blocker GP in '
              'merged diplomatic orders so the GP can break the GP-only '
              'frontier and pursue the turn-100 per-GP +3 net OW gain '
              'gate (SPEC § Observer goal phases (Full AI), EXPAND '
              'declare-war priority order; PR #2577 narrative).',
        );
      },
    );

    test(
      'suppresses GP blocker declareWar at quota in DEVELOP',
      () {
        final game = _scenarioGame(gp1OwProvinces: _gp1OwProvincesDevelop);
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _developSnapshot();

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.develop,
          reason:
              'Negative-control fixture must place GP in DEVELOP so the '
              'observer-quota gate inside '
              '`stalledGpBlockerDeclareWarTarget` (and the matching '
              'wrapper gate in `_plateauGpBlockerDeclarePlannerResultIfNeeded`) '
              'is exercised (otherwise this case would silently re-emit '
              'the EXPAND short-circuit and not verify the regression '
              'target).',
        );

        final orders = runDomainPlanners(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.diplomacy,
          seeds: AISeedBundle.fromTurnSeed(2509122),
          suggestionAPI: _emptyApi,
          economyPlan: _economyPlan,
        );

        expect(
          _declareWarTargets(orders),
          isNot(contains(_blockerGpId)),
          reason:
              'DEVELOP must drop the GP-only invadable blocker forced '
              'declare (the helper short-circuits at the observer-quota / '
              'stalled-OW gate, the wrapper short-circuits at the same '
              'gate, and DEVELOP scoring zeroes every declare-war '
              'candidate from the non-forced fall-through). Suppressing '
              'this declare preserves civilian work bandwidth for the '
              'turn-150 70% extractable-tile improvement gate (SPEC § '
              'Observer goal phases (Full AI), DEVELOP).',
        );
      },
    );

    test(
      'emits identical diplomatic orders for identical EXPAND inputs',
      () {
        final game = _scenarioGame(gp1OwProvinces: _gp1OwProvincesBelowQuota);
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _expandSnapshot();

        Orders runOnce(int turnSeed) => runDomainPlanners(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(turnSeed),
          suggestionAPI: _emptyApi,
          economyPlan: _economyPlan,
        );

        final firstRun = runOnce(2509123);
        final secondRun = runOnce(2509123);

        List<String> diplomaticFingerprint(Orders orders) => <String>[
          for (final o
              in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
            '${o.type}|${o.targetFactionId}|${o.overtureStage}',
        ];

        expect(
          diplomaticFingerprint(secondRun),
          diplomaticFingerprint(firstRun),
          reason:
              'Determinism (must-have #7): identical EXPAND-phase inputs '
              'on a GP-only invadable frontier must produce identical '
              'diplomatic orders across runs (forced-blocker declare is '
              'derived from `Game` state, not from rng-driven candidate '
              'sampling, so the fingerprint must be stable).',
        );
      },
    );
  });
}
