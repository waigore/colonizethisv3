/// Shared append helpers for per-order validation orchestration (Refs #3949
/// wave 3 lib DRY).
///
/// Collapses the structurally identical loops in [order_engine_validation.dart]
/// that append one [OrderValidationResult] per order and propagate the running
/// rejected flag (and optional mutable validator state such as treasury).
library;

import 'package:colonizethis_economy/colonizethis_economy.dart';

/// Appends one [OrderValidationResult] per order; short-circuits when [rejected].
/// Returns the new rejected flag (true if any result was rejected).
bool appendValidationResults<T>(
  List<OrderValidationResult> results,
  List<T> orders,
  bool rejected,
  OrderValidationResult Function(T order, bool previousRejected) validate,
) {
  var r = rejected;
  for (final o in orders) {
    final res = validate(o, r);
    results.add(res);
    if (!res.isAccepted) r = true;
  }
  return r;
}

/// Like [appendValidationResults] for validators that also return updated state
/// (e.g. treasury). Appends each result to [results], propagates [rejected],
/// and returns (rejected, finalState).
({bool rejected, S state}) appendValidationResultsWithState<T, S>(
  List<OrderValidationResult> results,
  List<T> orders,
  bool rejected,
  S initialState,
  ({OrderValidationResult result, S state}) Function(
    T order,
    bool previousRejected,
  )
  validate,
) {
  var r = rejected;
  var s = initialState;
  for (final o in orders) {
    final res = validate(o, r);
    results.add(res.result);
    if (!res.result.isAccepted) r = true;
    s = res.state;
  }
  return (rejected: r, state: s);
}
