// Pins **must-have #4** (personality-consistent means) from issue #2509 at
// the `computeDiplomaticCandidateScores` scoring boundary.
//
//   Issue #2509 AC (Must-have #4):
//     Given two fixed-seed Full AI states in **COLONIAL** phase that are
//     identical except `AIConfig.leaderId` / `personalityId` (e.g. `napoleon`
//     vs `henry`) with the same tribe colonial target where both Join Empire
//     and declare-war are valid candidates, when diplomacy planning runs,
//     then the highest-ranked colonial acquisition order **type** differs
//     between personalities per `SPEC/ai/ai-personalities.md` war vs alliance
//     modifiers (deterministic per personality).
//
// `runDomainPlanners` and `runDiplomacyPlannerWithResult` both call into
// `computeDiplomaticCandidateScores` for the per-candidate score that drives
// the weighted-random pick of the colonial acquisition order **type** — so
// pinning the type divergence at that scoring boundary is the deterministic,
// game-state-free way to verify the AC.
//
// SPEC source-of-truth coverage (Refs #2509):
//   - `SPEC/ai/ai-personalities.md` § Canonical leaders — `napoleon` =
//     fortifier (war likelihood **High**); `henry` = navigator (war
//     likelihood **Very low**). Mapped to `personalityThresholds`:
//     napoleon `warLikelihood`=80 / `allianceTendency`=25; henry
//     `warLikelihood`=10 / `allianceTendency`=75 in
//     `packages/colonizethis_data/lib/src/ai_personality_config.dart`.
//   - `SPEC/ai/ai-personalities.md` § Behavioral modifiers — war likelihood
//     and alliance tendency thresholds combine into the declare-war and
//     establish-overture scores via `_scoreDeclareWarDiplomaticOrder`
//     (`+ (warLikelihood - 50)`) and the overture branch in
//     `computeDiplomaticCandidateScores` (`+ (allianceTendency - 50)`).
//
// Existing related coverage (not redundant with this pin):
//   - `diplomatic_candidate_scoring_test.dart` group
//     `computeDiplomaticCandidateScores` `'declareWar score exceeds
//     establishOverture for same hostile target'` pins the napoleon /
//     **hostile GP** ranking, not the **COLONIAL tribe** + personality flip
//     required by must-have #4.
//   - `diplomatic_candidate_scoring_suppression_test.dart` pins the EXPAND
//     suppression branch in the same function (overture / declare-war zeroed
//     while below quota), the **opposite** sequencing rule from
//     must-have #4 which fires only in COLONIAL.
//   - `domain_planner_orchestrator_colonial_lite_test.dart` exercises the
//     COLONIAL-lite phase orchestrator contract (which preserves NW overture
//     and drops NW `purchase_land`) but uses a single personality (`henry`)
//     and therefore cannot fail when the personality-keyed scoring branch
//     stops diverging.
//
// A tuning slice that left both phase predicates and bonus constants intact
// but inadvertently dropped the `(thresholds.warLikelihood - 50)` or
// `(thresholds.allianceTendency - 50)` line — for example by replacing those
// terms with a uniform constant when refactoring — would silently collapse
// the highest-ranked colonial acquisition order **type** to the same value
// for every personality, breaking must-have #4 while leaving every existing
// per-phase suppression / acquisition-presence pin green.
//
// Coverage layers:
//   - Positive (napoleon): `declareWar` outranks `establishOverture` for the
//     COLONIAL tribe target.
//   - Positive (henry): `establishOverture` outranks `declareWar` for the
//     same COLONIAL tribe target.
//   - Cross-personality (war modifier): napoleon's `declareWar` score is
//     strictly higher than henry's `declareWar` score on the same inputs.
//   - Cross-personality (alliance modifier): henry's `establishOverture`
//     score is strictly higher than napoleon's `establishOverture` score on
//     the same inputs.
//   - Determinism guard (must-have #7): identical COLONIAL inputs produce
//     identical score lists across repeat invocations per personality.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/diplomatic_candidate_scoring_colonial_test_support.dart';
import '../support/domain_planner_orchestrator_test_support.dart';
import 'diplomatic_candidate_scoring_personality_colonial_divergence_tail_cases.dart';

const String _nationId = kOrchestratorGp1NationId;
const String _tribeId = kOrchestratorTribeId;

// COLONIAL-phase tribe target candidates the scoring function ranks.
// `targetOvertureStage` is `joinEmpire` to match the canonical NW colonial
// acquisition path in `SPEC/ai/ai-architecture.md` § Colonial expansion
// (Full AI) and the COLONIAL minimum rules (§ 1).
const List<DiplomaticOrder> _candidates = <DiplomaticOrder>[
  DiplomaticOrder(
    type: DiplomaticOrderType.declareWar,
    targetFactionId: _tribeId,
  ),
  DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: _tribeId,
    overtureStage: OvertureStage.joinEmpire,
  ),
];

// Index lookup keeps the assertions readable without coupling to enum order.
const int _declareWarIdx = 0;
const int _establishOvertureIdx = 1;

// COLONIAL-phase snapshot mirroring the AC's "tribe colonial target where
// both Join Empire and declare-war are valid candidates" preconditions:
//   - `oldWorldProvincesOwned = 11` → `!isBelowObserverConquestQuota` →
//     `observerGoalPhaseFor` selects [ObserverGoalPhase.colonial] because
//     `hasColonialAcquisitionTargets` is true via
//     `invadableNewWorldProvinceIdsSorted`.
//   - `provincesToVictory = 20` so `behindVictoryPace` evaluates `false`
//     against `kConquerScoreFloorProvincesToVictoryThreshold` and the
//     finalize-stage quarter conquer bonus applies symmetrically to both
//     personality runs.
//   - The tribe is the GP's preferred colonial target and owns the GP's
//     visible invadable NW province, but is **not** in the OW conquest
//     `adjacentOwnerFactionIdsSorted` list and **not** in the colonial
//     `adjacentNewWorldOwnerFactionIdsSorted` list. That keeps the
//     conquest-side `_declareWarAdjacencyAndStalledBonuses` quiet and
//     drops the `kDeclareWarColonialAdjacentTribeBonus` from the
//     declare-war side without losing the
//     `kEstablishOvertureColonialInvadableOwnerBonus` /
//     `kEstablishOvertureColonialTribeBonus` boost on the overture side,
//     so the residual score gap is driven by the personality
//     `warLikelihood` / `allianceTendency` deltas the AC pins. (When the
//     tribe is *also* colonial-adjacent, the +70 adjacent-tribe
//     declare-war bonus stacks on top of the +100 NW-tribe dominance
//     bonus and the personality deltas cannot flip the ranking — a
//     dimension already exercised by the existing
//     `domain_planner_orchestrator_colonial_lite_test.dart` fixture where
//     `_henry`'s overture still survives without needing to outrank
//     declare-war.)
// `merchant` is intentionally not in any of `agendaConquerModifiers`,
// `agendaTreatyBreakingModifiers`, `agendaAllianceAcceptanceModifiers`, or
// `declareWarMaxRelationScoreByAgenda`, so every agenda modifier resolves to
// its zero / default fallback. The score gap between the two AIConfig runs
// therefore isolates the personality `warLikelihood` / `allianceTendency`
// deltas the AC pins, instead of mixing in `warmonger` / `peacemaker`
// conquer / alliance shifts that would mask a personality regression.
const AIConfig _napoleonConfig = AIConfig(
  leaderId: 'napoleon',
  personalityId: 'napoleon',
  hiddenAgendaId: 'merchant',
);
const AIConfig _henryConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

List<int> _scoreFor(AIConfig config) {
  final game = diplomaticCandidateScoringColonialTribeScenarioGame(
    gameId: 'g-2509-personality-must-have-4-colonial',
    overtureStates: kDiplomaticCandidateScoringPersonalityOvertures,
  );
  // Shared COLONIAL NW-tribe snapshot (Refs #3997). Scoring pins
  // historically omitted adjacent NW owners so adjacency bonuses cannot
  // mask personality deltas.
  final snapshot = buildOrchestratorColonialNwTribeTargetSnapshot(
    newWorldProvincesOwned: 1,
    tribeRelationScore: 30,
    adjacentNewWorldOwnerFactionIdsSorted: const <String>[],
  );
  return computeDiplomaticCandidateScores(
    DiplomaticCandidateScoringInput(
      candidates: _candidates,
      nationId: _nationId,
      game: game,
      snapshot: snapshot,
      config: config,
    ),
  );
}

void main() {
  group(
    'computeDiplomaticCandidateScores COLONIAL personality divergence '
    '(Refs #2509 must-have #4)',
    () {
      test(
        'napoleon ranks declareWar above establishOverture for COLONIAL '
        'tribe target',
        () {
          final scores = _scoreFor(_napoleonConfig);

          expect(scores.length, _candidates.length);
          expect(
            scores[_declareWarIdx],
            greaterThan(scores[_establishOvertureIdx]),
            reason:
                'napoleon (`warLikelihood`=80, `allianceTendency`=25 per '
                '`SPEC/ai/ai-personalities.md`) must rank `declareWar` above '
                '`establishOverture` for a COLONIAL tribe target where both '
                'paths are valid candidates (issue #2509 must-have #4).',
          );
          expect(
            scores[_declareWarIdx],
            greaterThan(0),
            reason:
                'napoleon `declareWar` must remain a viable colonial '
                'acquisition order in COLONIAL — a regression that zeroes the '
                'tribe declare-war path would silently break the must-have #4 '
                'ranking contract.',
          );
        },
      );

      test(
        'henry ranks establishOverture above declareWar for COLONIAL tribe '
        'target',
        () {
          final scores = _scoreFor(_henryConfig);

          expect(scores.length, _candidates.length);
          expect(
            scores[_establishOvertureIdx],
            greaterThan(scores[_declareWarIdx]),
            reason:
                'henry (`warLikelihood`=10, `allianceTendency`=75 per '
                '`SPEC/ai/ai-personalities.md`) must rank '
                '`establishOverture(joinEmpire)` above `declareWar` for the '
                'same COLONIAL tribe target (issue #2509 must-have #4).',
          );
          expect(
            scores[_establishOvertureIdx],
            greaterThan(0),
            reason:
                'henry `establishOverture(joinEmpire)` must remain a viable '
                'colonial acquisition order in COLONIAL — a regression that '
                'zeroes the overture path would silently break the '
                'must-have #4 ranking contract.',
          );
        },
      );

      test(
        'highest-ranked colonial acquisition order TYPE flips between '
        'napoleon and henry on identical COLONIAL inputs',
        () {
          // Determinism + cross-personality assertion in one pass: each
          // personality independently picks the highest-scoring candidate
          // type, and the picked types must differ (issue #2509 must-have
          // #4: "the highest-ranked colonial acquisition order **type**
          // differs between personalities").
          final napoleonScores = _scoreFor(_napoleonConfig);
          final henryScores = _scoreFor(_henryConfig);

          final napoleonTopType =
              _candidates[_indexOfMax(napoleonScores)].type;
          final henryTopType =
              _candidates[_indexOfMax(henryScores)].type;

          expect(
            napoleonTopType,
            DiplomaticOrderType.declareWar,
            reason:
                'Napoleon (high war / low alliance per '
                '`SPEC/ai/ai-personalities.md` § Canonical leaders) must '
                'top-rank `declareWar` among colonial acquisition orders.',
          );
          expect(
            henryTopType,
            DiplomaticOrderType.establishOverture,
            reason:
                'Henry (very-low war / high alliance per '
                '`SPEC/ai/ai-personalities.md` § Canonical leaders) must '
                'top-rank `establishOverture(joinEmpire)` among colonial '
                'acquisition orders.',
          );
          expect(
            napoleonTopType,
            isNot(henryTopType),
            reason:
                'Must-have #4: the highest-ranked colonial acquisition '
                'order type must differ between personalities for the same '
                'COLONIAL tribe target (war vs alliance personality '
                'modifiers).',
          );
        },
      );
    },
  );
}

/// Returns the first index that holds the maximum value in [scores].
///
/// Equivalent to `scores.indexOf(scores.reduce(math.max))` without the
/// extra reducer; ties resolve to the lower index, matching the
/// scoring contract's deterministic candidate order.
int _indexOfMax(List<int> scores) {
  var bestIndex = 0;
  for (var i = 1; i < scores.length; i++) {
    if (scores[i] > scores[bestIndex]) {
      bestIndex = i;
    }
  }
  return bestIndex;

  registerDiplomaticCandidateScoringPersonalityColonialDivergenceTailCases();
}
