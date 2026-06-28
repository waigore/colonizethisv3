/// Shared "canonical order, first failure" cost-check idiom for the economy
/// layer.
///
/// Recruit-worker affordability ([canAffordRecruitWorker], `worker_action_cost.dart`)
/// and build-unit affordability (`_resolveBuildPlanForCatalog`, `build_cost.dart`)
/// both evaluate a fixed priority sequence of preconditions and return the
/// first failing reason string. This helper centralizes that control flow so
/// the canonical priority order (tech → workers → treasury → materials) and the
/// failure-reason vocabulary stay consistent across both paths (Refs #3517
/// Cluster 2).
///
/// The helper is pure and silent (no logging, no global scans) so it is safe on
/// the turn-resolution hot path per
/// `.cursor/rules/colonizethis-turn-resolution-budget.mdc`.
library;

/// A single precondition in a cost-check sequence.
///
/// [check] returns `true` when the precondition is satisfied and `false` when
/// it fails; [failReason] is the user-visible reason string returned when
/// [check] evaluates to `false`.
typedef CostPrecondition = ({String failReason, bool Function() check});

/// Evaluates [preconditions] in list order and returns the [failReason] of the
/// first record whose [check] returns `false`, or `null` when every [check]
/// passes.
///
/// Evaluation short-circuits: once a [check] fails, no later [check] closures
/// run. Callers therefore order the records by canonical priority (e.g.
/// tech → workers → treasury → materials) so the surfaced reason matches the
/// highest-priority unmet precondition.
String? checkPreconditionsInOrder(List<CostPrecondition> preconditions) {
  for (final precondition in preconditions) {
    if (!precondition.check()) {
      return precondition.failReason;
    }
  }
  return null;
}
