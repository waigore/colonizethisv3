import 'planning_helpers.dart' show planningListEquals;

/// Shared value-class shape for phase-planner destination filters (Refs #3822
/// Phase 4 / #3967 step 5). Concrete plan types expose domain-specific field
/// names while storing the shared province/owner list pair here so
/// [ExpandMilitaryPlan] / [ColonialMilitaryPlan] / naval plan shells do not
/// re-declare identical private fields and equality.
abstract base class PhaseDestinationResult {
  const PhaseDestinationResult({
    required List<String> priorityProvinceIdsSorted,
    required List<String> priorityTargetOwnerFactionIdsSorted,
  }) : _priorityProvinceIdsSorted = priorityProvinceIdsSorted,
       _priorityTargetOwnerFactionIdsSorted =
           priorityTargetOwnerFactionIdsSorted;

  final List<String> _priorityProvinceIdsSorted;
  final List<String> _priorityTargetOwnerFactionIdsSorted;

  List<String> get priorityProvinceIdsSorted => _priorityProvinceIdsSorted;

  List<String> get priorityTargetOwnerFactionIdsSorted =>
      _priorityTargetOwnerFactionIdsSorted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is PhaseDestinationResult &&
          planningListEquals(
            priorityProvinceIdsSorted,
            other.priorityProvinceIdsSorted,
          ) &&
          planningListEquals(
            priorityTargetOwnerFactionIdsSorted,
            other.priorityTargetOwnerFactionIdsSorted,
          );

  @override
  int get hashCode => Object.hash(
    Object.hashAll(priorityProvinceIdsSorted),
    Object.hashAll(priorityTargetOwnerFactionIdsSorted),
  );
}
