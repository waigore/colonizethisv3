part of 'colonial_phase_planner.dart';

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
          planningListEquals(
            priorityDestinationProvinceIdsSorted,
            other.priorityDestinationProvinceIdsSorted,
          ) &&
          planningListEquals(
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
///     declare-war target chosen by [planColonialAcquisition] when the
///     acquisition method resolves to [AcquisitionMethod.declareWar]
///     (issue #2509 § planColonialAcquisition Acquisition method 3).
///     When non-null, the planner restricts conquest destinations to
///     NW provinces owned by that faction (Priority 1). The argument
///     is not constrained to a specific faction class — tribes, minor
///     nations, and Great Powers are all valid targets per the spec;
///     the acquisition planner only ever returns tribe / minor ids
///     because Method 3 structurally excludes GP-owned NW invadable,
///     but [planColonialMilitary] does not re-narrow that argument so
///     the orchestrator stays free to pass any at-war target.
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
  expand_phase_planner.ExpandEconomyPlan expandEconomyPlan =
      expand_phase_planner.ExpandEconomyPlan.defaultPlan,
}) {
  if (isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned) &&
      !isNwLockRecoveryPathEActive(
        snapshot: snapshot,
        expandEconomyPlan: expandEconomyPlan,
      )) {
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
