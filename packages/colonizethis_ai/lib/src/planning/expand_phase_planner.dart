/// EXPAND-phase planner (Refs #2509 S2 / S10).
///
/// Phase planner module from the single-goal architecture in
/// [GitHub issue #2509](https://github.com/waigore/colonizethisv3/issues/2509)
/// and `SPEC/ai/ai-architecture.md` § Observer goal phases. The planner is a
/// pure-function module that makes one primary decision per domain with no
/// cross-phase score aggregation.
///
/// EXPAND phase goal: reach `kObserverConquestMinOwProvincesPerGp` Old World
/// provinces. All NW code is structurally bypassed — the EXPAND planner never
/// imports `colonial_phase_planner.dart`, never queries [ColonialSummary],
/// never generates NW `declareWar` / `establishOverture` /
/// `purchase_land` / `build_improvement`, and never queues NW conquest army
/// moves. Suppression is an architectural property of the module, not a
/// runtime predicate check (Refs #2509 § EXPAND phase planner Suppressions).
/// The structural NW-suppression AC for the planner **set as a whole**
/// (issue #2509 § Phase planner unit tests § "EXPAND NW suppression";
/// `SPEC/ai/phase-planner-architecture.md` § Acceptance criteria) is
/// pinned in `test/planning/expand_phase_planner_nw_suppression_test.dart`,
/// which exercises all four EXPAND planners (`planExpandDeclareWar`,
/// `planExpandPeace`, `planExpandEconomy`, `planExpandMilitary`) against a
/// NW-rich fixture and asserts the merged output set carries no NW orders.
///
/// Callers are expected to dispatch to this module **only** when
/// `observerGoalPhaseFor` resolves to `ObserverGoalPhase.expand`; the planner
/// functions themselves do not re-check the phase, matching the convention
/// established by `develop_phase_planner.dart` (Refs #2509 S4).
///
/// Orchestrator wiring (#2509 S5) is now in place: `phase_planner_dispatch.dart`
/// calls `planExpandPeace`, `planExpandDeclareWar`, `planExpandEconomy`, and
/// `planExpandMilitary` for every EXPAND-phase player and threads the result
/// through `PhasePlanOutcome`; `domain_planner_orchestrator.dart` consumes the
/// outcome via `gpPeaceTargetsFromPhasePlan` /
/// `gpExpandDeclareWarTargetFromPhasePlan` so EXPAND domain decisions reach
/// the resolver without re-checking the phase. The legacy
/// `expandPhaseGpPeaceTargets` helper still lives in
/// `observer_goal_phase.dart` because the no-`phasePlan` fallback path through
/// `collectStalledGreatPowerPeaceTargets` keeps it on the production hot path
/// alongside the EXPAND ratchet aggregator; `colonial_pressure.dart` and
/// `diplomacy_planner_peace_targets.dart` were removed in #2509 S1, with their
/// helpers canonical here (and in `observer_goal_phase.dart` for the
/// cross-phase composite peace aggregators). Both `expandPhaseGpPeaceTargets`
/// and `planExpandPeace` are pinned at the function-unit level.
///
/// In-module contracts shipped to date (see issue #2509 § EXPAND phase
/// planner for the full set):
///
///   `planExpandPeace(game, snapshot) → List<String>`
///     Returns the deterministic list of at-war Great Powers the active
///     player should `offerPeace` toward in EXPAND. Defaults to peacing
///     **all** at-war GPs except the GP owning the primary invadable Old
///     World frontier (`primaryInvadableOldWorldGpBlocker`). The lone GP
///     blocker is also peaced when the war is a mutual-plateau sole-GP
///     stalemate on a GP-only invadable frontier with no uninvaded OW
///     minors remaining (Refs #2509 § EXPAND phase planner § planExpandPeace
///     "peace to exit stalemate").
///
///   `planExpandDeclareWar(game, snapshot) → String?`
///     Returns the deterministic factionId of the next declare-war target
///     for the active EXPAND player, scanning [ConquestSummary]
///     `invadableProvinceIdsSorted` in priority order: (1) adjacent
///     minor not yet at war, (2) already-at-war minor (formalize war so
///     conquest army-move pass fires), (3) sole GP frontier blocker on a
///     GP-only mutual-plateau frontier when our regiment count and
///     treasury cover engagement. Returns `null` when no priority arm
///     applies (Refs #2509 § EXPAND phase planner § planExpandDeclareWar).
///     The "suggestDeclareWarOrders rejects" runtime gate noted in the
///     spec is enforced at the orchestrator layer (#2509 S5) so this
///     module remains a pure-function planner.
///
///   `planExpandEconomy(game, snapshot) → ExpandEconomyPlan`
///     Returns the EXPAND-phase economy directive for the active player:
///     `forceCheapestRegimentBuild` (set the orchestrator build threshold
///     to zero and pick the cheapest regiment in
///     [RegimentEconomyCatalog]) and / or `boostTreasuryRecoveryCargo`
///     (raise economy weight for overseas cargo so riches deliver to
///     stockpile before the next build pass). Implements the
///     three-arm decision tree from issue #2509 § EXPAND phase planner
///     § planExpandEconomy (zero-regiment rebuild, insufficient-regiment
///     rebuild with affordable treasury, treasury-recovery cargo boost).
///     Effective treasury is `Player.treasury` plus
///     [pendingRichesTreasuryDelta] so the planner aligns with build
///     validation that already credits same-turn `richesToTreasury`
///     phase income (Refs #2509 § Observer goal phases § EXPAND
///     "Pending riches treasury").
///
///   `planExpandMilitary(game, snapshot, declaredWarTargetFactionId)
///                                                  → ExpandMilitaryPlan`
///     Returns the deterministic OW-only conquest destination filter for
///     the active EXPAND player. The plan carries the priority subset of
///     [ConquestSummary.invadableProvinceIdsSorted] (always OW by
///     construction — see `_invadableOldWorldProvinceIds` in the
///     perception snapshot builder) that conquest army moves should
///     target this turn: provinces owned by the declare-war target when
///     one was chosen, otherwise provinces owned by any at-war faction.
///     Returns [ExpandMilitaryPlan.defaultPlan] (no constraint) for the
///     outer EXPAND guards (at quota, missing player, empty invadable
///     frontier) and for the priority arms that resolve to an empty
///     province set; the orchestrator (#2509 S5) treats `defaultPlan`
///     as "free choice within OW invadable" and a non-default plan as
///     "restrict conquest army moves to this subset" (Refs #2509 §
///     EXPAND phase planner § planExpandMilitary "Use existing
///     runConquestArmyMovePlanner with EXPAND-only destination filter").
///     Structural NW suppression: the planner never reads
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] so a New
///     World invadable province cannot appear in the plan even if the
///     snapshot exposes one.
library;


import '../perception/perception_snapshot.dart';
import 'planning_imports.dart' hide cheapestRegimentBuildTreasuryCost;
import 'expand_peace_frontier_helpers.dart';
import 'planning_helpers.dart'
    show gpFactionIdsAtWarWith, peaceTargetsExcludingBlocker;

export 'expand_peace_frontier_helpers.dart';
export 'expand_phase_planner_peer_peace.dart';
export 'expand_phase_planner_economy.dart';
export 'expand_phase_planner_feedstock_acquisition.dart';
export 'expand_phase_planner_gp_blocker_peace.dart';
export 'expand_phase_planner_military.dart';
export 'expand_phase_planner_peace_default_start.dart';
export 'expand_phase_planner_peace_targets.dart';
export 'expand_phase_planner_declare_war.dart';


/// Returns the deterministic list of at-war Great Powers the active player
/// should `offerPeace` toward this turn while in EXPAND phase.
///
/// Contract (issue #2509 § EXPAND phase planner § planExpandPeace, extended
/// by issue #2847 § H4 § H4-a):
///
///   "Peace ALL at-war Great Powers, with ONE exception:
///    → Keep fighting the GP that owns the primary invadable OW frontier
///      blocker (primaryInvadableOldWorldGpBlocker), UNLESS:
///      - It's a mutual-plateau sole GP war on a GP-only cleared frontier
///        with no uninvaded minors (peace to exit stalemate), OR
///      - The sole at-war GP is the only owner of OW provinces adjacent to
///        the active player's territory (geographic peer-war lock) and both
///        sides are in the mutual-plateau below-quota band — the uninvaded
///        OW minor pivot is unreachable from the active player's anchors,
///        so the minor-pivot guard is irrelevant (Refs #2847 § H4-a)."
///
/// Inputs:
///   - [game]: used to (a) filter [ThreatSummary.atWarWith] down to Great
///     Power factions via [Game.playerById]; (b) compute the primary OW
///     frontier blocker by mapping invadable OW provinces to current
///     owners; (c) detect uninvaded OW minors still in play; (d) check
///     whether the invadable OW frontier is held only by GPs (no minor
///     border).
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ThreatSummary.atWarWith], [ConquestSummary.invadableProvinceIdsSorted],
///     [ConquestSummary.adjacentOwnerFactionIdsSorted], and
///     [ConquestSummary.oldWorldProvincesOwned] for the mutual-plateau
///     comparison.
///
/// Output:
///   - Empty list when no Great Powers are at war with the active player.
///   - Empty list when the sole at-war GP **is** the primary OW invadable
///     blocker and neither carve-out applies (keep fighting the blocker;
///     default EXPAND posture).
///   - All GPs sorted ascending when the primary blocker is `null` or not
///     among the at-war GPs (peace ALL: the legacy "no exception applies"
///     case).
///   - All GPs except the blocker sorted ascending when the blocker is
///     among the at-war GPs and no carve-out fires (peace ALL
///     except the blocker).
///   - The single GP (still sorted as a 1-element list) when the
///     mutual-plateau sole-GP carve-out fires: exactly one GP at war,
///     that GP owns the primary OW invadable blocker, both sides are in
///     the stalled below-quota plateau band
///     ([isMutualBelowQuotaPlateauPeer]), the invadable frontier is
///     GP-only ([isOldWorldGpOnlyInvadableFrontier]), and no uninvaded
///     OW minors remain ([hasUninvadedOldWorldMinor] is false).
///   - The single GP (still sorted as a 1-element list) when the
///     geographic peer-war lock carve-out fires: exactly one GP at war,
///     that GP owns the primary OW invadable blocker, both sides are in
///     the mutual-plateau below-quota band, and
///     [ConquestSummary.adjacentOwnerFactionIdsSorted] is exactly
///     `[blocker]` — the at-war peer GP is the only faction owning OW
///     provinces adjacent to the active player's anchors, so any
///     uninvaded OW minor is geographically unreachable (Refs #2847
///     § H4-a).
///
/// The function is pure and deterministic — identical inputs always yield
/// identical lists (Refs #2509 Must-have #7).
List<String> planExpandPeace({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.isEmpty) {
    return const [];
  }

  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null || !gpWars.contains(blocker)) {
    return gpWars..sort();
  }

  if (gpWars.length == 1 &&
      isMutualBelowQuotaPlateauPeer(
        ownOw: snapshot.conquest.oldWorldProvincesOwned,
        partnerOw: provinceCountOwnedBy(game, blocker),
      )) {
    if (expandIsGeographicPeerWarLock(snapshot: snapshot, peerGpId: blocker)) {
      return List<String>.unmodifiable(gpWars);
    }
    if (isOldWorldGpOnlyInvadableFrontier(
          game: game,
          snapshot: snapshot,
        ) &&
        !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
      return List<String>.unmodifiable(gpWars);
    }
  }

  return peaceTargetsExcludingBlocker(factionIds: gpWars, blocker: blocker);
}
