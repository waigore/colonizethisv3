/// COLONIAL-phase planner (Refs #2509 S3 / S10).
///
/// Phase planner module from the single-goal architecture in
/// [GitHub issue #2509](https://github.com/waigore/colonizethisv3/issues/2509)
/// and `SPEC/ai/ai-architecture.md` § Observer goal phases. The planner is a
/// pure-function module that makes one primary decision per domain with no
/// cross-phase score aggregation.
///
/// COLONIAL phase goal: transfer every `newWorld|` province to GP ownership
/// using the fastest legal acquisition path (Join Empire, `purchase_land`,
/// or `declareWar` + invasion). Callers are expected to dispatch to this
/// module **only** when `observerGoalPhaseFor` resolves to
/// `ObserverGoalPhase.colonial`; the planner functions themselves do not
/// re-check the phase, matching the convention established by
/// `develop_phase_planner.dart` (Refs #2509 S4) and
/// `expand_phase_planner.dart` (Refs #2509 S2).
///
/// Wiring this module into the orchestrator, replacing the legacy
/// `colonialPhaseGpPeaceTargets` helper in `observer_goal_phase.dart`, and
/// retiring the `colonial_pressure.dart` / `diplomacy_planner_peace_targets.dart`
/// ratchet helpers are out of scope for this slice (tracked under S5 / S1
/// of #2509). Both the legacy `colonialPhaseGpPeaceTargets` helper and the
/// new `planColonialPeace` function remain pinned at the function-unit
/// level until the orchestrator rewrite reconciles them, so this slice
/// carries **zero behavior change** and **zero regression risk** for live
/// AI play.
///
/// In-module contracts shipped to date (see issue #2509 § COLONIAL phase
/// planner for the full set, including the deferred
/// `planColonialAcquisition`, `planColonialNaval`,
/// `planColonialCivilian`, `planColonialLiteOvertures`, and
/// `planColonialLiteNaval`):
///
///   `planColonialPeace(game, snapshot) → List<String>`
///     Returns the deterministic list of at-war Great Powers the active
///     player should `offerPeace` toward in COLONIAL. Defaults to peacing
///     **all** at-war GPs except the one identified by
///     [primaryColonialGpBlocker] (the GP owning the most invadable
///     `newWorld|` provinces -- the primary colonial NW frontier blocker).
///     The new spec text from issue #2509 § COLONIAL phase planner §
///     planColonialPeace is "Peace all at-war Great Powers, with ONE
///     exception: Keep fighting a GP that owns a province blocking the
///     primary colonial NW target". Tribe and minor at-war factions are
///     filtered out via [Game.playerById] returning `null` for non-player
///     ids -- COLONIAL diplomatic peace is GP-vs-GP only; tribe/minor
///     colonial wars are pursued through other phase-planner contracts
///     (`planColonialAcquisition` for `establishOverture` / Join Empire
///     / `purchase_land`, [planColonialMilitary] for NW conquest army
///     moves; the acquisition planner is deferred to a follow-up S3
///     slice).
///
///   `planColonialMilitary(game, snapshot,
///                         colonialDeclaredWarTargetFactionId)
///                                                 → ColonialMilitaryPlan`
///     Returns the deterministic NW-only conquest destination filter for
///     the active COLONIAL player. The plan carries the priority subset
///     of [ColonialSummary.invadableNewWorldProvinceIdsSorted] (always
///     NW by construction in the perception-snapshot builder) that
///     conquest army moves should target this turn: provinces owned by
///     the colonial declare-war target when one was chosen, otherwise
///     provinces owned by any at-war faction (tribe / minor / GP).
///     Returns [ColonialMilitaryPlan.defaultPlan] (no constraint) for
///     the outer COLONIAL guards (below quota, missing player, empty
///     NW invadable frontier) and for the priority arms that resolve
///     to an empty province set; the orchestrator (#2509 S5) treats
///     `defaultPlan` as "free choice within NW invadable" and a
///     non-default plan as "restrict NW conquest army moves to this
///     subset" (Refs #2509 § COLONIAL phase planner § planColonialMilitary
///     "Use runConquestArmyMovePlanner with NW destination filter").
///     Structural OW-defend / regiment-rebuild orders are emitted by
///     sibling planners (the EXPAND economy planner and the conquest
///     army-move planner running in defend mode); planColonialMilitary
///     only emits the NW conquest destination filter so the orchestrator
///     can drive `runConquestArmyMovePlanner` toward the colonial
///     target.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'observer_goal_phase.dart' show primaryColonialGpBlocker;

/// Returns the deterministic list of at-war Great Powers the active player
/// should `offerPeace` toward this turn while in COLONIAL phase.
///
/// Contract (issue #2509 § COLONIAL phase planner § planColonialPeace):
///
///   "Peace all at-war Great Powers, with ONE exception:
///    → Keep fighting a GP that owns a province blocking the primary
///      colonial NW target (primaryColonialGpBlocker).
///
///    Never peace tribe/minor colonial targets until:
///    → Objective met (tribe no longer owns the target NW province), OR
///    → War is unwinnable (zero regiments, no treasury, can't build)."
///
/// The tribe/minor exception is handled structurally by this function: a
/// tribe or minor in [ThreatSummary.atWarWith] does not satisfy
/// `game.playerById(factionId) != null` (only [Player] entries are
/// returned from that lookup), so non-GP factions are filtered out before
/// the blocker pass. `offerPeace` toward tribes / minors therefore is
/// **never** emitted by this planner — the tribe / minor war-continuation
/// rule is preserved by exclusion. Conversely, `establishOverture`,
/// `purchase_land`, and NW conquest are emitted by sibling phase-planner
/// functions (`planColonialAcquisition`, `planColonialMilitary` —
/// deferred to follow-up S3 slices) rather than reasoned about here.
///
/// Inputs:
///   - [game]: used to (a) filter [ThreatSummary.atWarWith] down to
///     Great Power factions via [Game.playerById]; (b) compute the
///     primary colonial NW frontier blocker via
///     [primaryColonialGpBlocker], which maps the active player's
///     visible invadable NW provinces to their current owners and picks
///     the GP with the largest invadable-NW ownership share.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ThreatSummary.atWarWith] and
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] (consumed
///     transitively by [primaryColonialGpBlocker]).
///
/// Output:
///   - Empty list when no Great Powers are at war with the active
///     player (the GP filter loop produces an empty `gpWars` and the
///     trailing sort is a no-op).
///   - All GPs sorted ascending when the blocker is `null` (no
///     invadable NW province is owned by a Great Power) or when the
///     blocker is not among the at-war GPs (the membership guard arm).
///     The legacy "no exception applies" path: peace **all** live GP
///     fronts.
///   - All GPs except the blocker sorted ascending when the blocker is
///     among the at-war GPs (canonical COLONIAL-peace happy path:
///     keep fighting the colonial blocker, peace every other GP front).
///   - Empty list when the active player is at war with exactly one
///     GP **and** that GP is the colonial blocker (the lone war IS the
///     blocker war -- keep fighting it; nothing else to peace).
///   - The single GP (as a 1-element list) when the active player is
///     at war with exactly one GP and that GP is **not** the colonial
///     blocker. This is the explicit divergence from the legacy
///     [colonialPhaseGpPeaceTargets] helper, which short-circuits with
///     `return const []` when `gpWars.length <= 1`. The new spec wording
///     "Peace all at-war Great Powers" does not carry the legacy
///     `>= 2 GPs` guard: every non-blocker GP front must peace so the
///     orchestrator (#2509 S5) can drive NW acquisition / improvement
///     work without an idle GP-vs-GP distraction war.
///
/// The function is pure and deterministic — identical inputs always yield
/// identical lists (Refs #2509 Must-have #7).
List<String> planColonialPeace({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  if (gpWars.isEmpty) {
    return const [];
  }

  final blocker = primaryColonialGpBlocker(game: game, snapshot: snapshot);
  if (blocker == null || !gpWars.contains(blocker)) {
    return gpWars..sort();
  }

  return <String>[
    for (final factionId in gpWars)
      if (factionId != blocker) factionId,
  ]..sort();
}

/// COLONIAL-phase conquest destination filter returned by
/// [planColonialMilitary].
///
/// Two ascending-sorted lists describe the priority subset of NW
/// invadable provinces (and the owning faction(s)) that conquest army
/// moves should target this turn. The lists never contain Old World
/// provinces — structural suppression in [planColonialMilitary] (the
/// planner only reads [ColonialSummary.invadableNewWorldProvinceIdsSorted],
/// which is NW-only by construction in the perception-snapshot builder).
///
/// The orchestrator (Refs #2509 S5) consumes the plan as a filter on
/// `runConquestArmyMovePlanner`:
///   - [defaultPlan] (`priorityDestinationProvinceIdsSorted` empty) =
///     "no constraint"; the orchestrator chooses freely from the full
///     NW invadable set (the legacy COLONIAL fall-back behaviour).
///   - A non-default plan = "restrict NW conquest destinations to this
///     subset". Empty plans never carry
///     [priorityTargetOwnerFactionIdsSorted] entries; non-empty plans
///     always carry at least one owner faction id.
///
/// `const`-friendly so the default "no override" return uses a single
/// shared instance ([defaultPlan]) without per-call allocations on the
/// hot AI path. Value equality compares both list contents so tests can
/// assert against literal constructions without relying on identity.
class ColonialMilitaryPlan {
  const ColonialMilitaryPlan({
    required this.priorityDestinationProvinceIdsSorted,
    required this.priorityTargetOwnerFactionIdsSorted,
  });

  /// Reusable "no override" plan returned for non-COLONIAL callers, GPs
  /// below the observer conquest quota, the empty-NW-invadable guard,
  /// and the priority-arm fall-through (declared colonial target owns
  /// nothing in NW invadable and no at-war faction owns NW invadable
  /// either).
  static const ColonialMilitaryPlan defaultPlan = ColonialMilitaryPlan(
    priorityDestinationProvinceIdsSorted: <String>[],
    priorityTargetOwnerFactionIdsSorted: <String>[],
  );

  /// Subset of [ColonialSummary.invadableNewWorldProvinceIdsSorted]
  /// (NW only) whose owners match the priority-arm filter for this
  /// turn. Sorted ascending so identical inputs yield identical lists
  /// (Refs #2509 Must-have #7). Empty for [defaultPlan].
  final List<String> priorityDestinationProvinceIdsSorted;

  /// Faction ids of the owners covered by
  /// [priorityDestinationProvinceIdsSorted]. Sorted ascending and
  /// deduplicated:
  ///   - Single-element list when the declared colonial-target arm
  ///     fires ([planColonialMilitary] § Priority 1). The target may
  ///     be a tribe, minor nation, or Great Power — the planner does
  ///     not partition by faction class because COLONIAL acquisition
  ///     via `declareWar` (issue #2509 § planColonialAcquisition step
  ///     3) can pick any of those.
  ///   - One or more entries (sorted at-war owners) when the at-war
  ///     fallback arm fires ([planColonialMilitary] § Priority 2).
  ///   - Empty for [defaultPlan].
  final List<String> priorityTargetOwnerFactionIdsSorted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColonialMilitaryPlan &&
          _colonialListEquals(
            priorityDestinationProvinceIdsSorted,
            other.priorityDestinationProvinceIdsSorted,
          ) &&
          _colonialListEquals(
            priorityTargetOwnerFactionIdsSorted,
            other.priorityTargetOwnerFactionIdsSorted,
          );

  @override
  int get hashCode => Object.hash(
    Object.hashAll(priorityDestinationProvinceIdsSorted),
    Object.hashAll(priorityTargetOwnerFactionIdsSorted),
  );

  @override
  String toString() =>
      'ColonialMilitaryPlan('
      'priorityDestinationProvinceIdsSorted: $priorityDestinationProvinceIdsSorted, '
      'priorityTargetOwnerFactionIdsSorted: $priorityTargetOwnerFactionIdsSorted)';
}

bool _colonialListEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Returns the deterministic COLONIAL-phase conquest destination filter
/// for the active player as a [ColonialMilitaryPlan].
///
/// Contract (issue #2509 § COLONIAL phase planner § planColonialMilitary):
///
///   "NW army moves toward the primary colonial target's provinces.
///      → Use runConquestArmyMovePlanner with NW destination filter
///        (targets in invadableNewWorldProvinceIdsSorted owned by the
///        declare-war target faction).
///      → OW defend/regiment rebuild allowed."
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) for the
///     defensive guard and walks the province-owner map
///     ([getProvinceOwnerMap]) to partition
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] by owner
///     faction.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] (the NW-only
///     candidate pool),
///     [ConquestSummary.oldWorldProvincesOwned] (the COLONIAL outer
///     quota gate — see "below quota -> default" guard below), and
///     [ThreatSummary.atWarWith] (the Priority 2 fallback when no
///     colonial declare-war target is given).
///   - [colonialDeclaredWarTargetFactionId]: optional colonial
///     declare-war target chosen by `planColonialAcquisition`
///     (deferred S3 slice) when the acquisition method resolves to
///     `declareWar` (the "Acquisition method 3" in issue #2509 §
///     planColonialAcquisition). When non-null, the planner restricts
///     conquest destinations to NW provinces owned by that faction
///     (Priority 1). The argument is not constrained to a specific
///     faction class — tribes, minor nations, and Great Powers are all
///     valid targets per the spec.
///
/// Priority arms (first match wins; each arm produces a sorted-ascending,
/// deduplicated province list):
///   1. **Declared colonial target** — when
///      [colonialDeclaredWarTargetFactionId] is non-null and owns at
///      least one province in
///      [ColonialSummary.invadableNewWorldProvinceIdsSorted], the plan
///      restricts to those provinces and lists only the target as
///      `priorityTargetOwnerFactionIdsSorted`.
///   2. **At-war owners fallback** — when no colonial target is given
///      and at least one faction in [ThreatSummary.atWarWith] owns an
///      NW invadable province, the plan restricts to the union of
///      those provinces and lists the at-war owners sorted ascending.
///   3. **Default plan** — when the declared colonial target owns
///      nothing in NW invadable, or when no target is given and no
///      at-war faction owns NW invadable, or for the outer guards
///      (below quota, missing player, empty NW invadable). Empty plan
///      signals the orchestrator to fall back to its existing
///      free-choice colonial-conquest behaviour over the full NW
///      invadable set.
///
/// Structural OW suppression: this function reads only
/// [ColonialSummary.invadableNewWorldProvinceIdsSorted] (NW-only by
/// builder contract). It never reads
/// [ConquestSummary.invadableProvinceIdsSorted], so an Old World
/// province cannot appear in the plan even when the snapshot exposes
/// one. The OW defend / regiment-rebuild work mentioned in the spec
/// (the "OW defend/regiment rebuild allowed" bullet) lives in the
/// EXPAND economy planner and the conquest army-move planner running
/// in defend mode — those siblings remain free to act in OW while
/// planColonialMilitary drives the NW conquest filter (Refs #2509 §
/// COLONIAL phase planner § planColonialMilitary).
///
/// Outer guard rationale: [isBelowObserverConquestQuota] returning
/// `true` means the active player has not reached
/// [kObserverConquestMinOwProvincesPerGp] (the EXPAND -> COLONIAL
/// transition threshold). The function returns [defaultPlan] in that
/// case so a mis-dispatched call from EXPAND territory cannot emit NW
/// destinations. The symmetric guard in `planExpandMilitary` short-circuits
/// when the same predicate returns `false` (at/above quota). Both
/// guards are documented as defensive — the structural caller still
/// drives phase dispatch via `observerGoalPhaseFor`.
///
/// The function is pure and deterministic — identical inputs always
/// yield identical [ColonialMilitaryPlan]s (Refs #2509 Must-have #7).
ColonialMilitaryPlan planColonialMilitary({
  required Game game,
  required AIWorldSnapshot snapshot,
  String? colonialDeclaredWarTargetFactionId,
}) {
  if (isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return ColonialMilitaryPlan.defaultPlan;
  }
  if (game.playerById(snapshot.playerId) == null) {
    return ColonialMilitaryPlan.defaultPlan;
  }
  final invadable = snapshot.colonial.invadableNewWorldProvinceIdsSorted;
  if (invadable.isEmpty) {
    return ColonialMilitaryPlan.defaultPlan;
  }

  final provinceOwner = getProvinceOwnerMap(game);

  if (colonialDeclaredWarTargetFactionId != null) {
    final destinations = <String>[
      for (final pid in invadable)
        if (provinceOwner[pid] == colonialDeclaredWarTargetFactionId) pid,
    ];
    if (destinations.isEmpty) {
      return ColonialMilitaryPlan.defaultPlan;
    }
    destinations.sort();
    return ColonialMilitaryPlan(
      priorityDestinationProvinceIdsSorted: List<String>.unmodifiable(
        destinations,
      ),
      priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(<String>[
        colonialDeclaredWarTargetFactionId,
      ]),
    );
  }

  final atWarSet = snapshot.threats.atWarWith.toSet();
  final atWarOwners = <String>{};
  final destinations = <String>[];
  for (final pid in invadable) {
    final owner = provinceOwner[pid];
    if (owner == null) continue;
    if (!atWarSet.contains(owner)) continue;
    destinations.add(pid);
    atWarOwners.add(owner);
  }
  if (destinations.isEmpty) {
    return ColonialMilitaryPlan.defaultPlan;
  }
  destinations.sort();
  final owners = atWarOwners.toList()..sort();
  return ColonialMilitaryPlan(
    priorityDestinationProvinceIdsSorted: List<String>.unmodifiable(
      destinations,
    ),
    priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(owners),
  );
}
