// Pins issue #2509 **must-have #6** (intervention tolerance) at the
// `computeDiplomaticCandidateScores` scoring boundary.
//
//   Issue #2509 AC (Must-have #6, intervention tolerance — AI section):
//     Given a fixed-seed Full AI state where a **tribe** is a valid
//     declare-war target, colonial-support weights are active, and
//     intervention-risk scoring would discourage war on a Great Power,
//     when `suggestDeclareWarOrders` (or equivalent scoring entrypoint)
//     runs, then the tribe target is **not** unconditionally excluded by
//     a hard skip guard (score may be low but must remain in the
//     candidate set; deterministic for fixed seed).
//
// `runDomainPlanners` and `runDiplomacyPlannerWithResult` both call into
// `computeDiplomaticCandidateScores` — the deterministic, game-state-free
// scoring entrypoint described in the AC. Pinning the tribe declare-war
// **non-zero** score under elevated intervention-risk preconditions at
// that boundary is the directly testable form of the AC: any refactor
// that converts the existing scoring penalty
// (`_interventionRiskPenalty` in `war_desire_calculator.dart`, -8 per
// other-GP embassy, capped at -24) into a hard skip — for example by
// inserting `if (interventionEmbassyCount >= N) return 0;` into
// `_scoreDeclareWarDiplomaticOrder` or `_declareWarSuppressedScore` —
// would silently break the AC while every existing per-phase pin stays
// green.
//
// SPEC source-of-truth coverage (Refs #2509):
//   - Issue § Requirements § Must-have — AI behavior #6 — *"Intervention
//     tolerance: AI remains willing to declare on tribes/minors despite
//     intervention-risk scoring; optimize weights, do not add a hard
//     'never declare' guard for NW."*
//   - `SPEC/ai/ai-architecture.md` § Observer goal phases (Full AI) — the
//     **COLONIAL** row authorises tribe colonial declare-war targets
//     (`COLONIAL minimum rules` § 2 — *"Target tribe/minor owners of
//     sea-reachable unowned NW provinces or adjacent colonial objectives"*).
//
// Existing related coverage (not redundant with this pin):
//   - `war_desire_score_test.dart` group `computeWarDesireScore` test
//     *'minor target with intervention risk and no navy reduces war
//     desire'* pins the **war-desire scalar** (`lessThan(50)`) under
//     intervention overtures — it does **not** assert the integrated
//     `computeDiplomaticCandidateScores` declare-war path stays non-zero
//     after every `_declareWarSuppressed*Score` short-circuit runs, and
//     it deliberately mixes the no-navy penalty into the same reduction.
//   - `domain_planner_orchestrator_colonial_tribe_declare_war_test.dart`
//     pins the COLONIAL tribe declare-war **presence** AC but uses a
//     fixture with **no** other-GP embassies, so a tuning slice that
//     introduces an intervention-risk hard-skip guard could silently
//     break must-have #6 while leaving that pin green.
//   - `diplomatic_candidate_scoring_personality_colonial_divergence_test.dart`
//     pins the **personality** delta for the same scoring entrypoint
//     under zero intervention risk; this pin holds the orthogonal
//     intervention-risk axis steady.
//
// Coverage layers:
//   - Positive (presence): under elevated intervention risk (3 other GPs
//     hold embassy overtures with the tribe = max -24 war-desire penalty
//     per `_interventionRiskPenalty`), the tribe declare-war candidate
//     keeps a strictly positive score from
//     `computeDiplomaticCandidateScores`.
//   - Negative (delta): the same fixture **without** the intervention
//     overtures produces a strictly higher tribe declare-war score —
//     proving intervention risk is still applied as a graded scoring
//     penalty, not a hard skip nor a no-op.
//   - Ranking cross-check: the tribe declare-war score stays strictly
//     positive **and** is reported in the same `candidates` slot the
//     planner consumes (catches a refactor that reorders the return
//     list and silently maps the tribe slot to zero from an unrelated
//     candidate).
//   - Determinism (must-have #7): repeat invocations of the same
//     scoring entrypoint on identical inputs yield identical score lists
//     under high intervention risk.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/diplomatic_candidate_scoring_colonial_test_support.dart';
import '../support/domain_planner_orchestrator_test_support.dart';

const String _nationId = kOrchestratorGp1NationId;
const String _tribeId = kOrchestratorTribeId;

// COLONIAL-phase tribe target. Only a single declare-war candidate is
// scored so the assertion can pin the tribe declare-war slot directly
// without depending on the relative ordering of unrelated candidates.
const List<DiplomaticOrder> _tribeDeclareWarCandidates = <DiplomaticOrder>[
  DiplomaticOrder(
    type: DiplomaticOrderType.declareWar,
    targetFactionId: _tribeId,
  ),
];

// `merchant` is intentionally not in any of `agendaConquerModifiers`,
// `agendaTreatyBreakingModifiers`, `agendaAllianceAcceptanceModifiers`,
// or `declareWarMaxRelationScoreByAgenda`, so every agenda modifier
// resolves to its zero / default fallback. The intervention-risk delta
// the AC pins is then driven by the war-desire bonus path inside
// `_declareWarCoreBonuses` rather than by hidden-agenda shifts that
// would change between fixtures.
//
// `victoria` (personalityId) keeps `warLikelihood` = 50 / 
// `allianceTendency` = 50, so the personality term in
// `_declareWarCoreBonuses` is exactly zero — the residual cross-fixture
// score delta isolates the intervention-risk path the AC pins.
const AIConfig _aiConfig = AIConfig(
  leaderId: 'victoria',
  personalityId: 'victoria',
  hiddenAgendaId: 'merchant',
);

/// COLONIAL-phase snapshot mirroring the AC's "tribe is a valid
/// declare-war target, colonial-support weights are active"
/// preconditions:
///   - `oldWorldProvincesOwned = 11` → `!isBelowObserverConquestQuota` →
///     `observerGoalPhaseFor` selects [ObserverGoalPhase.colonial]
///     because `hasColonialAcquisitionTargets` is true via
///     `invadableNewWorldProvinceIdsSorted`.
///   - `provincesToVictory = 20` so `behindVictoryPace` evaluates
///     `false` against `kConquerScoreFloorProvincesToVictoryThreshold`
///     and the finalize-stage quarter conquer bonus applies
///     symmetrically to both intervention variants.
///   - The tribe is the GP's preferred colonial target **and** owns the
///     visible invadable NW province. Deliberately keeping the tribe
///     **out** of OW `adjacentOwnerFactionIdsSorted` and NW
///     `adjacentNewWorldOwnerFactionIdsSorted` quiets
///     `_declareWarAdjacencyAndStalledBonuses` and drops
///     `kDeclareWarColonialAdjacentTribeBonus` (+70) from the
///     declare-war side so the residual score delta is dominated by
///     the war-desire / intervention-risk path the AC pins.
List<int> _scoreTribeDeclareWar({
  required List<OvertureState> overtureStates,
}) {
  final game = diplomaticCandidateScoringColonialTribeScenarioGame(
    gameId: 'g-2509-intervention-tribe-tolerance',
    overtureStates: overtureStates,
    includeBystanderGreatPowers: true,
    homeArmyRegimentUnitId: 'u_gp1_home',
  );
  // Shared COLONIAL NW-tribe snapshot (Refs #3997). Scoring pins
  // historically omitted adjacent NW owners so adjacency bonuses cannot
  // mask intervention deltas.
  final snapshot = buildOrchestratorColonialNwTribeTargetSnapshot(
    newWorldProvincesOwned: 1,
    tribeRelationScore: 30,
    adjacentNewWorldOwnerFactionIdsSorted: const <String>[],
  );
  return computeDiplomaticCandidateScores(
    DiplomaticCandidateScoringInput(
      candidates: _tribeDeclareWarCandidates,
      nationId: _nationId,
      game: game,
      snapshot: snapshot,
      config: _aiConfig,
    ),
  );
}

void main() {
  group(
    'computeDiplomaticCandidateScores COLONIAL tribe intervention '
    'tolerance (Refs #2509 must-have #6)',
    () {
      test(
        'tribe declareWar candidate stays in the candidate set under '
        'max intervention risk (3 other-GP embassies)',
        () {
          final scores = _scoreTribeDeclareWar(
            overtureStates: <OvertureState>[
              kDiplomaticCandidateScoringGp1TribeEmbassy,
              ...kDiplomaticCandidateScoringInterventionEmbassies,
            ],
          );

          expect(
            scores.length,
            _tribeDeclareWarCandidates.length,
            reason:
                '`computeDiplomaticCandidateScores` must return one score '
                'per input candidate — a refactor that filters out the '
                'tribe declare-war slot under intervention risk would '
                'silently break must-have #6 by reshaping the list.',
          );
          expect(
            scores.single,
            greaterThan(0),
            reason:
                'Issue #2509 must-have #6 forbids a hard "never declare" '
                'guard on tribe declare-war candidates under elevated '
                'intervention-risk preconditions. The score may be low '
                '(intervention risk is applied as a graded war-desire '
                'penalty in `_interventionRiskPenalty`, -8 per other-GP '
                'embassy, capped at -24) but it **must remain > 0** so '
                'the candidate stays selectable by the weighted-random '
                'pick downstream of `computeDiplomaticCandidateScores`.',
          );
        },
      );

      test(
        'tribe declareWar score is strictly higher without intervention '
        'overtures (intervention risk applied as graded penalty, not a '
        'hard skip nor a no-op)',
        () {
          final withoutIntervention = _scoreTribeDeclareWar(
            overtureStates: const <OvertureState>[
              kDiplomaticCandidateScoringGp1TribeEmbassy,
            ],
          );
          final withIntervention = _scoreTribeDeclareWar(
            overtureStates: <OvertureState>[
              kDiplomaticCandidateScoringGp1TribeEmbassy,
              ...kDiplomaticCandidateScoringInterventionEmbassies,
            ],
          );

          expect(
            withoutIntervention.single,
            greaterThan(withIntervention.single),
            reason:
                'Removing the three other-GP embassies must raise the '
                'tribe declare-war score, proving intervention risk is '
                'still applied as a graded scoring penalty rather than '
                'collapsed into a no-op or upgraded into a hard skip. '
                'If both scores are equal a tuning slice has silently '
                'dropped the `_interventionRiskPenalty` contribution; if '
                'the high-intervention score is zero must-have #6 has '
                'regressed.',
          );
          expect(
            withIntervention.single,
            greaterThan(0),
            reason:
                'Cross-check: the high-intervention variant must still be '
                '> 0 alongside the strictly-greater delta, so the test '
                'fails distinctly for the hard-skip regression versus '
                'the no-op regression.',
          );
        },
      );

      test(
        'tribe declareWar score is deterministic for the same inputs '
        'under high intervention risk (must-have #7)',
        () {
          final first = _scoreTribeDeclareWar(
            overtureStates: <OvertureState>[
              kDiplomaticCandidateScoringGp1TribeEmbassy,
              ...kDiplomaticCandidateScoringInterventionEmbassies,
            ],
          );
          final second = _scoreTribeDeclareWar(
            overtureStates: <OvertureState>[
              kDiplomaticCandidateScoringGp1TribeEmbassy,
              ...kDiplomaticCandidateScoringInterventionEmbassies,
            ],
          );

          expect(
            second,
            equals(first),
            reason:
                'Issue #2509 must-have #7 — same `Game` state + same '
                '`computeDiplomaticCandidateScores` inputs must produce '
                'identical score lists across repeat invocations. A '
                'refactor that introduces non-determinism in the '
                'intervention-risk path (e.g. iterating overture states '
                'in non-stable order) would surface here.',
          );
        },
      );
    },
  );
}
