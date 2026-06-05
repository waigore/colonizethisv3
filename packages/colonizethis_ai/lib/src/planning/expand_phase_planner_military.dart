part of 'expand_phase_planner.dart';

// EXPAND-phase conquest destination filter ([planExpandMilitary] /
// [ExpandMilitaryPlan]) and the same-turn declare-war coordination helpers,
// extracted from `expand_phase_planner.dart` for maintainability
// (Refs #3278 file-split). Behaviour-preserving move: same library scope
// (this is a `part of` the EXPAND planner library), so imports, shared
// helpers, and visibility are unchanged.

/// EXPAND-phase conquest destination filter returned by [planExpandMilitary].
///
/// Two ascending-sorted lists describe the priority subset of OW
/// invadable provinces (and the owning faction(s)) that conquest army
/// moves should target this turn. The lists never contain New World
/// provinces — structural suppression in [planExpandMilitary] (the
/// planner only reads [ConquestSummary.invadableProvinceIdsSorted],
/// which is OW-only by construction in the perception-snapshot builder).
///
/// The orchestrator (Refs #2509 S5) consumes the plan as a filter on
/// `runConquestArmyMovePlanner`:
///   - [defaultPlan] (`priorityDestinationProvinceIdsSorted` empty) =
///     "no constraint"; the orchestrator chooses freely from the full
///     OW invadable set (legacy behavior).
///   - A non-default plan = "restrict OW conquest destinations to this
///     subset". Empty plans never carry [priorityTargetOwnerFactionIdsSorted]
///     entries; non-empty plans always carry at least one owner.
///
/// `const`-friendly so the default "no override" return uses a single
/// shared instance ([defaultPlan]) without per-call allocations on the
/// hot AI path.
class ExpandMilitaryPlan {
  const ExpandMilitaryPlan({
    required this.priorityDestinationProvinceIdsSorted,
    required this.priorityTargetOwnerFactionIdsSorted,
  });

  /// Reusable "no override" plan returned for non-EXPAND callers, GPs
  /// at quota, the empty-invadable guard, and the priority-arm
  /// fall-through (declared-war target owns nothing in OW invadable
  /// and no at-war faction owns OW invadable either).
  static const ExpandMilitaryPlan defaultPlan = ExpandMilitaryPlan(
    priorityDestinationProvinceIdsSorted: <String>[],
    priorityTargetOwnerFactionIdsSorted: <String>[],
  );

  /// Subset of [ConquestSummary.invadableProvinceIdsSorted] (OW only)
  /// whose owners match the priority-arm filter for this turn. Sorted
  /// ascending so identical inputs yield identical lists (Refs #2509
  /// Must-have #7). Empty for [defaultPlan].
  final List<String> priorityDestinationProvinceIdsSorted;

  /// Faction ids of the owners covered by
  /// [priorityDestinationProvinceIdsSorted]. Sorted ascending and
  /// deduplicated:
  ///   - Single-element list when the declared-war target arm fires
  ///     ([planExpandMilitary] § Priority 1).
  ///   - One or more entries (sorted at-war owners) when the at-war
  ///     fallback arm fires ([planExpandMilitary] § Priority 2).
  ///   - Empty for [defaultPlan].
  final List<String> priorityTargetOwnerFactionIdsSorted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpandMilitaryPlan &&
          _listEquals(
            priorityDestinationProvinceIdsSorted,
            other.priorityDestinationProvinceIdsSorted,
          ) &&
          _listEquals(
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
      'ExpandMilitaryPlan('
      'priorityDestinationProvinceIdsSorted: $priorityDestinationProvinceIdsSorted, '
      'priorityTargetOwnerFactionIdsSorted: $priorityTargetOwnerFactionIdsSorted)';
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Returns the deterministic EXPAND-phase conquest destination filter
/// for the active player as an [ExpandMilitaryPlan].
///
/// Contract (issue #2509 § EXPAND phase planner § planExpandMilitary):
///
///   "Conquest army moves toward OW invadable provinces only.
///      → Source: invadableProvinceIdsSorted, filtered to provinces
///        owned by the declare-war target (or any at-war owner if no
///        target).
///      → Use existing runConquestArmyMovePlanner with EXPAND-only
///        destination filter.
///      → No NW army moves (structural — planner never queries
///        colonial summary)."
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) for the
///     defensive guard and walks the province-owner map
///     ([getProvinceOwnerMap]) to partition
///     [ConquestSummary.invadableProvinceIdsSorted] by owner faction.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ConquestSummary.invadableProvinceIdsSorted] (the OW-only
///     candidate pool),
///     [ConquestSummary.oldWorldProvincesOwned] (the EXPAND outer
///     quota gate), and [ThreatSummary.atWarWith] (the Priority 2
///     fallback when no declare-war target is given).
///   - [declaredWarTargetFactionId]: optional declare-war target from
///     [planExpandDeclareWar] for the same turn; when non-null, the
///     planner restricts conquest destinations to provinces owned by
///     that faction (Priority 1).
///
/// Priority arms (first match wins; each arm produces a sorted-ascending,
/// deduplicated province list):
///   1. **Declared-war target** — when [declaredWarTargetFactionId] is
///      non-null and owns at least one province in
///      [ConquestSummary.invadableProvinceIdsSorted], the plan
///      restricts to those provinces and lists only the target as
///      `priorityTargetOwnerFactionIdsSorted`.
///   2. **At-war owners fallback** — when no declare-war target is given
///      and at least one faction in [ThreatSummary.atWarWith] owns an
///      OW invadable province, the plan restricts to the union of those
///      provinces and lists the at-war owners sorted ascending.
///   3. **Default plan** — when the declare-war target owns nothing in
///      OW invadable, or when no declare-war target is given and no
///      at-war faction owns OW invadable, or for the outer guards (at
///      quota, missing player, empty OW invadable). Empty plan signals
///      the orchestrator to fall back to its existing free-choice
///      conquest behaviour over the full invadable set.
///
/// Structural NW suppression: this function reads only
/// [ConquestSummary.invadableProvinceIdsSorted] (OW-only by builder
/// contract). It never reads [ColonialSummary.invadableNewWorldProvinceIdsSorted],
/// so a New World province cannot appear in the plan even when the
/// snapshot exposes one (Refs #2509 § EXPAND phase planner
/// "Suppressions" / Phase planner unit tests § "EXPAND NW
/// suppression"). The actual order emission and the conquest army-move
/// pass live in `runConquestArmyMovePlanner`; the orchestrator (#2509
/// S5) wires this plan in as a filter on that pass.
///
/// The function is pure and deterministic — identical inputs always
/// yield identical [ExpandMilitaryPlan]s (Refs #2509 Must-have #7).
ExpandMilitaryPlan planExpandMilitary({
  required Game game,
  required AIWorldSnapshot snapshot,
  String? declaredWarTargetFactionId,
}) {
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return ExpandMilitaryPlan.defaultPlan;
  }
  if (game.playerById(snapshot.playerId) == null) {
    return ExpandMilitaryPlan.defaultPlan;
  }
  final invadable = snapshot.conquest.invadableProvinceIdsSorted;
  if (invadable.isEmpty) {
    return ExpandMilitaryPlan.defaultPlan;
  }

  final provinceOwner = getProvinceOwnerMap(game);

  if (declaredWarTargetFactionId != null) {
    final destinations = <String>[
      for (final pid in invadable)
        if (provinceOwner[pid] == declaredWarTargetFactionId) pid,
    ];
    if (destinations.isEmpty) {
      return ExpandMilitaryPlan.defaultPlan;
    }
    destinations.sort();
    return ExpandMilitaryPlan(
      priorityDestinationProvinceIdsSorted: List<String>.unmodifiable(
        destinations,
      ),
      priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(<String>[
        declaredWarTargetFactionId,
      ]),
    );
  }

  final atWarOwners = <String>{};
  final atWarSet = snapshot.threats.atWarWith.toSet();
  final destinations = <String>[];
  for (final pid in invadable) {
    final owner = provinceOwner[pid];
    if (owner == null) continue;
    if (!atWarSet.contains(owner)) continue;
    destinations.add(pid);
    atWarOwners.add(owner);
  }
  if (destinations.isEmpty) {
    return ExpandMilitaryPlan.defaultPlan;
  }
  destinations.sort();
  final owners = atWarOwners.toList()..sort();
  return ExpandMilitaryPlan(
    priorityDestinationProvinceIdsSorted: List<String>.unmodifiable(
      destinations,
    ),
    priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(owners),
  );
}

/// Returns the existing GP-vs-GP war partner targeting [targetGpId] in the
/// supplied [DiplomacyRelation], or `null` when the relation does not encode
/// such a war.
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) as a private
/// helper for [greatPowerWarCountOnTarget]: a same-turn declare-war scoring
/// helper consumed by `diplomatic_candidate_scoring_declare_war.dart` to
/// suppress dogpiles on GPs that are already at war with at least one other
/// GP, including same-turn declarations from earlier Full-AI players. The
/// private helper survives the planned deletion of `colonial_pressure.dart`
/// alongside its public callers (Refs #2509 § S1).
///
/// Returns:
///   - `null` when [rel] is not in `RelationState.atWar`.
///   - `null` when neither faction in the relation is [targetGpId].
///   - `null` when the non-target faction is not a Great Power
///     ([Game.playerById] returns `null`).
///   - The non-target faction's id when the relation pairs [targetGpId]
///     against a different Great Power in the at-war state.
String? _expandGpWarPartnerAgainstTarget(
  DiplomacyRelation rel,
  String targetGpId,
  Game game,
) {
  if (rel.state != RelationState.atWar) {
    return null;
  }
  if (rel.factionId1 == targetGpId && game.playerById(rel.factionId2) != null) {
    return rel.factionId2;
  }
  if (rel.factionId2 == targetGpId && game.playerById(rel.factionId1) != null) {
    return rel.factionId1;
  }
  return null;
}

/// True when [orders] contains a same-turn `declareWar` diplomatic order
/// pointing at [targetGpId].
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) as a private
/// helper for the same-turn declare-war fan-out walked by
/// [_expandAddSameTurnDeclareWarGpTargets]. Survives the planned deletion of
/// `colonial_pressure.dart` alongside its public callers.
bool _expandHasDeclareWarOnTarget(
  Iterable<DiplomaticOrder> orders,
  String targetGpId,
) {
  for (final order in orders) {
    if (order.type == DiplomaticOrderType.declareWar &&
        order.targetFactionId == targetGpId) {
      return true;
    }
  }
  return false;
}

/// Adds every Great Power declarer in [orders] that has a same-turn
/// `declareWar` order pointing at [targetGpId] into [atWarGpIds].
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) as a private
/// helper for [greatPowerWarCountOnTarget]. Walks
/// [Orders.diplomaticOrdersByPlayerId] in deterministic iteration order
/// over a per-player map; the helper only mutates [atWarGpIds] (a set,
/// so duplicates from resolved relations are folded in without altering
/// the public count).
///
/// Minor nations and tribes are skipped via [Game.playerById]; only
/// Great Power declarers contribute to the same-turn dogpile signal that
/// `diplomatic_candidate_scoring_declare_war.dart` uses to score
/// candidate declarations.
void _expandAddSameTurnDeclareWarGpTargets({
  required Game game,
  required String targetGpId,
  required Orders orders,
  required Set<String> atWarGpIds,
}) {
  for (final entry in orders.diplomaticOrdersByPlayerId.entries) {
    final declarerId = entry.key;
    if (game.playerById(declarerId) == null) {
      continue;
    }
    if (!_expandHasDeclareWarOnTarget(entry.value, targetGpId)) {
      continue;
    }
    atWarGpIds.add(declarerId);
  }
}

/// Returns the count of Great Powers currently warring against [targetGpId],
/// including same-turn declare-war orders from earlier Full-AI players in
/// [sameTurnPriorDiplomaticOrders] when supplied.
///
/// Same-turn declarers and resolved-relation partners are folded into a
/// shared [Set] so a GP that both declared this turn and already had an
/// at-war relation against [targetGpId] is counted only once. The set is
/// then collapsed to its length.
///
/// Consumers (`diplomatic_candidate_scoring_declare_war.dart` § war
/// concentration scoring) use the count to suppress dogpile-style
/// declarations when [targetGpId] is already engaged in multiple GP-vs-GP
/// wars (deterministic anti-dogpile gate; Refs #2509 § EXPAND phase
/// planner § declare-war suppression).
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) so the
/// declare-war coordination helper survives the planned deletion of
/// `colonial_pressure.dart`. Linear in
/// `(diplomacyRelations.length + sameTurnPriorDiplomaticOrders entries)`,
/// matching `colonizethis-turn-resolution-budget.mdc` § hot-loop
/// guidance (no global province / tile scans introduced by the move).
///
/// The function is pure and deterministic — identical inputs always yield
/// identical counts (Refs #2509 Must-have #7).
int greatPowerWarCountOnTarget({
  required Game game,
  required String targetGpId,
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  final atWarGpIds = <String>{};
  for (final rel in game.diplomacyRelations) {
    final partner = _expandGpWarPartnerAgainstTarget(rel, targetGpId, game);
    if (partner != null) {
      atWarGpIds.add(partner);
    }
  }
  if (sameTurnPriorDiplomaticOrders != null) {
    _expandAddSameTurnDeclareWarGpTargets(
      game: game,
      targetGpId: targetGpId,
      orders: sameTurnPriorDiplomaticOrders,
      atWarGpIds: atWarGpIds,
    );
  }
  return atWarGpIds.length;
}

/// True when [declarerFactionId] has a same-turn `declareWar` diplomatic
/// order pointing at [targetFactionId] in [sameTurnPriorDiplomaticOrders].
///
/// Returns `false` when [sameTurnPriorDiplomaticOrders] is `null` (no
/// earlier Full-AI player has committed orders yet this turn) so callers
/// can skip the same-turn check without a separate guard.
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) so the
/// declare-war ordering helper survives the planned deletion of
/// `colonial_pressure.dart`. The single live consumer is
/// `diplomatic_candidate_scoring_declare_war.dart` § same-turn
/// declare-war suppression, which uses the predicate to drop a
/// candidate when the prospective target has already declared back
/// against the active player earlier in the same turn (mutual
/// declarations are not re-issued).
///
/// The function is pure and deterministic — identical inputs always yield
/// identical results (Refs #2509 Must-have #7).
bool pendingDeclareWarFrom({
  required Orders? sameTurnPriorDiplomaticOrders,
  required String declarerFactionId,
  required String targetFactionId,
}) {
  if (sameTurnPriorDiplomaticOrders == null) {
    return false;
  }
  for (final order
      in sameTurnPriorDiplomaticOrders
              .diplomaticOrdersByPlayerId[declarerFactionId] ??
          const []) {
    if (order.type == DiplomaticOrderType.declareWar &&
        order.targetFactionId == targetFactionId) {
      return true;
    }
  }
  return false;
}
