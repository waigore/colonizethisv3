import 'planning_helpers.dart' show planningListEquals;

/// Shared value-class shape for phase-planner destination filters (Refs #3822
/// Phase 4). Concrete plan types expose domain-specific field names while
/// delegating equality to the shared province/owner list pair.
abstract base class PhaseDestinationResult {
  const PhaseDestinationResult();

  List<String> get priorityProvinceIdsSorted;
  List<String> get priorityTargetOwnerFactionIdsSorted;

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
