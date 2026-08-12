import 'phase_destination_result.dart';

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
final class ExpandMilitaryPlan extends PhaseDestinationResult {
  const ExpandMilitaryPlan({
    required List<String> priorityDestinationProvinceIdsSorted,
    required List<String> priorityTargetOwnerFactionIdsSorted,
  }) : super(
         priorityProvinceIdsSorted: priorityDestinationProvinceIdsSorted,
         priorityTargetOwnerFactionIdsSorted:
             priorityTargetOwnerFactionIdsSorted,
       );

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
  List<String> get priorityDestinationProvinceIdsSorted =>
      priorityProvinceIdsSorted;

  /// Faction ids of the owners covered by
  /// [priorityDestinationProvinceIdsSorted]. Sorted ascending and
  /// deduplicated:
  ///   - Single-element list when the declared-war target arm fires
  ///     ([planExpandMilitary] § Priority 1).
  ///   - One or more entries (sorted at-war owners) when the at-war
  ///     fallback arm fires ([planExpandMilitary] § Priority 2).
  ///   - Empty for [defaultPlan].
  @override
  List<String> get priorityTargetOwnerFactionIdsSorted =>
      super.priorityTargetOwnerFactionIdsSorted;

  @override
  String toString() =>
      'ExpandMilitaryPlan('
      'priorityDestinationProvinceIdsSorted: $priorityDestinationProvinceIdsSorted, '
      'priorityTargetOwnerFactionIdsSorted: $priorityTargetOwnerFactionIdsSorted)';
}
