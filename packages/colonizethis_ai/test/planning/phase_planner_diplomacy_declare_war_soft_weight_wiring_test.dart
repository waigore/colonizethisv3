// Unit tests for the Phase 3 soft-weight wiring of the diplomacy
// declare-war scoring path (Refs #2847).
//
// Mirrors `phase_planner_conquest_wiring_test.dart` for the
// declare-war NW colonial-pressure scoring sites. Pins the contract
// for `_DeclareWarTargetContext` weight derivation observed through
// `computeDiplomaticCandidateScores`:
//
//   - When a `PhasePlanOutcome` is threaded through with the default
//     soft-phase curve (`PhasePriorityWeights.earlySprintDefault`,
//     NW = 0.05), NW colonial declare-war candidates are NOT collapsed
//     to `kDeclareWarNonAdjacentSuppressedScore` under EXPAND or
//     COLONIAL-lite. The boolean structural suppression is replaced by
//     a `nwAcquisitionWeight <= 0.0` gate, and the default curve never
//     hits zero (Refs #2847 § Soft-phase priority weights).
//
//   - When an explicit `PhasePlanOutcome.priorityWeights` slot pins
//     `newWorldAcquisition = 0.0`, the EXPAND / COLONIAL-lite
//     suppression branches collapse NW colonial candidates exactly as
//     the legacy hard-suppress contract did. This is the regression
//     guard: a future refactor that misroutes the weight read must
//     produce a non-zero collapse score, surfacing the bug.
//
//   - Callers that omit `phasePlan` keep the pre-soft-phase behaviour
//     via the legacy `shouldSuppressNewWorldColonialOrders` -> `0.0`
//     mapping in `_DeclareWarTargetContext.build`.
//
// The boolean Phase 2 resolvers (`...ColonialPressureActive`,
// `...ExpandColonialSuppressionActive`,
// `...ColonialLiteSuppressionActive`,
// `...DevelopSuppressionActive`) remain pinned by
// `phase_planner_diplomacy_filter_test.dart`. This file targets only
// the scoring-path consumers that the Phase 3 slice migrated from
// those booleans to the weight.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// NW acquisition weight pinned to zero — emulates the legacy
// hard-suppress contract on the Phase 3 weight gate. The curve never
// emits this value in production, so any production regression
// pinning to zero would have to wire a deliberate override.
const PhasePriorityWeights _nwAcquisitionZero = PhasePriorityWeights(
  oldWorldConquest: 0.95,
  newWorldAcquisition: 0.0,
  oldWorldCivilian: 0.90,
  newWorldCivilian: 0.10,
);

const AIConfig _config = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

// Isolated snapshot for the Phase 3 wiring tests. The intent is to
// route a tribe declare-war candidate through the
// `_declareWarSuppressedExpandColonialScore` /
// `_declareWarSuppressedColonialLiteScore` branches and then into the
// declare-war bonus path WITHOUT triggering any unrelated
// suppression branch (stalled-OW frontier, adjacent-GP, war
// concentration, relation/cooldown). The discriminating signal
// becomes "did the EXPAND / COLONIAL-lite branch collapse the
// candidate to `kDeclareWarNonAdjacentSuppressedScore = 0`?".
//
// At-quota (`ow = kObserverConquestMinOwProvincesPerGp = 10`) keeps
// `stalledOwExpansion = false` so the stalled-OW frontier branch
// cannot fire. `provincesToVictory = 14` keeps `behindVictoryPace =
// false` (well below
// `kConquerScoreFloorProvincesToVictoryThreshold = 20`). Tribe1
// appears in `adjacentNewWorldOwnerFactionIdsSorted` and owns a NW
// invadable, so the legacy EXPAND / COLONIAL-lite branches would
// collapse the candidate (per their `isColonialAdjacentOwner ||
// ownsInvadableNw || isTribeTarget` predicate). Under the Phase 3
// soft-weight gate, the same candidate must survive when
// `nwAcquisitionWeight > 0.0` and pick up the
// `kDeclareWarColonialAdjacentTribeBonus`.
const AIWorldSnapshot _atQuotaColonialAdjacentTribeSnap = AIWorldSnapshot(
  playerId: 'gp1',
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(
    oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
    provincesToVictory: 14,
    adjacentOwnerFactionIdsSorted: [],
  ),
  colonial: ColonialSummary(
    invadableNewWorldProvinceIdsSorted: ['newWorld|tribe1_a'],
    adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
  ),
  economy: EconomySummary(),
  relations: {},
);

Game _buildGame() => Game(
  id: 'g-phase3-diplomacy-soft-weight',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
    oldWorld: const RegionData(),
    newWorld: const RegionData(
      provinces: [
        Province(
          id: 'newWorld|tribe1_a',
          regionId: 'newWorld',
          ownerId: 'tribe1',
        ),
      ],
    ),
  ),
  players: const [Player(id: 'gp1', displayName: 'P1', isHuman: false)],
  tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
  aiControlByGpId: const {'gp1': true},
);

int _tribeDeclareWarScore({required PhasePlanOutcome? phasePlan}) {
  return computeDiplomaticCandidateScores(
    candidates: const [
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: 'tribe1',
      ),
    ],
    nationId: 'gp1',
    game: _buildGame(),
    snapshot: _atQuotaColonialAdjacentTribeSnap,
    config: _config,
    phasePlan: phasePlan,
  ).single;
}

void main() {
  group('Phase 3 diplomacy declare-war soft-weight wiring (Refs #2847)', () {
    test(
      'EXPAND default soft curve keeps NW tribe declare-war scorable '
      '(no boolean structural collapse)',
      () {
        // Pre-Phase-3: under EXPAND, `_declareWarSuppressedExpandColonialScore`
        // collapsed tribe targets to `kDeclareWarNonAdjacentSuppressedScore`.
        // Post-Phase-3: the suppression gates on
        // `nwAcquisitionWeight <= 0.0`; the default early-sprint curve
        // emits `newWorldAcquisition = 0.05`, so the tribe target now
        // survives the structural collapse and earns the
        // `kDeclareWarColonialAdjacentTribeBonus` (Refs #2847 §
        // Soft-phase priority weights).
        const phasePlan = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
        final score = _tribeDeclareWarScore(phasePlan: phasePlan);
        expect(
          score,
          greaterThanOrEqualTo(kDeclareWarColonialAdjacentTribeBonus),
          reason:
              'EXPAND with default soft curve must NOT collapse NW tribe '
              'declare-war via the EXPAND-colonial suppression branch — '
              'the candidate must reach the colonial-adjacent tribe '
              'bonus path (weight = 0.05 > 0).',
        );
      },
    );

    test(
      'COLONIAL-lite default soft curve keeps NW tribe declare-war scorable',
      () {
        // Same contract as the EXPAND case — COLONIAL-lite shares the
        // early-sprint curve plateau and now defers to the soft-weight
        // gate instead of the boolean phase check.
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonialLite,
        );
        final score = _tribeDeclareWarScore(phasePlan: phasePlan);
        expect(
          score,
          greaterThanOrEqualTo(kDeclareWarColonialAdjacentTribeBonus),
          reason:
              'COLONIAL-lite with default soft curve must NOT collapse NW '
              'tribe declare-war via the COLONIAL-lite suppression branch — '
              'the candidate must reach the colonial-adjacent tribe '
              'bonus path (weight = 0.05 > 0).',
        );
      },
    );

    test(
      'EXPAND with explicit nwAcquisition = 0.0 collapses NW tribe '
      'declare-war (legacy hard-suppress equivalent)',
      () {
        // Regression guard: pinning `newWorldAcquisition = 0.0` on the
        // phase-plan must restore the legacy hard-suppress contract so
        // a future refactor that misroutes the weight read surfaces as
        // a non-zero scored candidate.
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          priorityWeights: _nwAcquisitionZero,
        );
        final score = _tribeDeclareWarScore(phasePlan: phasePlan);
        expect(
          score,
          kDeclareWarNonAdjacentSuppressedScore,
          reason:
              'EXPAND with nwAcquisition = 0.0 must collapse NW tribe '
              'declare-war via the EXPAND-colonial suppression branch '
              '(weight gate restored to the legacy hard-suppress).',
        );
      },
    );

    test(
      'COLONIAL-lite with explicit nwAcquisition = 0.0 collapses NW tribe '
      'declare-war (legacy hard-suppress equivalent)',
      () {
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonialLite,
          priorityWeights: _nwAcquisitionZero,
        );
        final score = _tribeDeclareWarScore(phasePlan: phasePlan);
        expect(
          score,
          kDeclareWarNonAdjacentSuppressedScore,
          reason:
              'COLONIAL-lite with nwAcquisition = 0.0 must collapse NW '
              'tribe declare-war via the COLONIAL-lite suppression branch.',
        );
      },
    );

    test(
      'DEVELOP suppression contract is preserved (DEVELOP collapses every '
      'declare-war candidate independent of NW weight)',
      () {
        // The DEVELOP-wide collapse path is unchanged by the Phase 3
        // slice — `_declareWarSuppressedDevelopPhaseScore` still routes
        // off the boolean resolver and collapses every declare-war
        // candidate before the EXPAND / COLONIAL-lite branches run.
        // This pin guards against an accidental migration of the
        // DEVELOP branch to the NW weight (which would let DEVELOP
        // emit declare-war once NW weight > 0).
        const phasePlan = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
        final score = _tribeDeclareWarScore(phasePlan: phasePlan);
        expect(
          score,
          kDeclareWarNonAdjacentSuppressedScore,
          reason:
              'DEVELOP must still collapse every declare-war candidate '
              'via _declareWarSuppressedDevelopPhaseScore — the Phase 3 '
              'slice migrated EXPAND / COLONIAL-lite only.',
        );
      },
    );

    test(
      'null phase plan with at-quota colonial-acquisition snapshot keeps '
      'NW tribe declare-war scorable (legacy 1.0 weight branch)',
      () {
        // No phase plan threaded through: `_DeclareWarTargetContext.build`
        // falls back to the legacy
        // `shouldSuppressNewWorldColonialOrders` -> `1.0 / 0.0` mapping.
        // The at-quota snapshot has visible colonial acquisition
        // targets (`hasColonialAcquisitionTargets = true`), no stalled-OW
        // GP-blocker focus, and is at quota — so the legacy compound
        // resolves the NW colonial-pressure predicate to `true` and
        // maps the weight to `1.0`. The candidate therefore survives
        // the EXPAND / COLONIAL-lite branches via the same `> 0.0`
        // gate as the phase-plan path.
        final score = _tribeDeclareWarScore(phasePlan: null);
        expect(
          score,
          greaterThanOrEqualTo(kDeclareWarColonialAdjacentTribeBonus),
          reason:
              'Null phase plan must use the legacy weight mapping; with '
              'visible colonial acquisition targets the weight maps to '
              '1.0 and the candidate survives via the `> 0.0` gate.',
        );
      },
    );

    test(
      'deterministic across repeated EXPAND default-curve calls '
      '(Must-have #7)',
      () {
        // Pure-function determinism: identical inputs must yield
        // identical scores across calls so the soft-weight gate does
        // not introduce stochastic behaviour.
        const phasePlan = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
        final a = _tribeDeclareWarScore(phasePlan: phasePlan);
        final b = _tribeDeclareWarScore(phasePlan: phasePlan);
        final c = _tribeDeclareWarScore(phasePlan: phasePlan);
        expect(a, b, reason: 'two-call determinism');
        expect(b, c, reason: 'three-call determinism');
      },
    );
  });
}
