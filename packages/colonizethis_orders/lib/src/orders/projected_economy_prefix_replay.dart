/// Shared projected-economy prefix replay for full-pass and incremental
/// validation paths (Refs #3949 wave 3 lib DRY).
///
/// Collapses the structurally identical recruit-worker / build prefix loops:
/// replay accepted prefix orders through a projected validator once, cache the
/// resulting ledgers, and short-circuit when a prior prefix rejection is known.
/// Callers keep category-specific validator factories and candidate probes.
library;

import 'package:colonizethis_economy/colonizethis_economy.dart'
    show OrderValidationResult;
import 'package:colonizethis_models/colonizethis_models.dart';

/// Worker-pool / stockpile / treasury snapshot after a successful prefix replay.
typedef ProjectedResourceLedgers = ({
  Stockpile stockpile,
  int treasury,
  WorkerPool workers,
});

/// Ensures [existingOrders] replay onto a projected validator once.
///
/// Returns cached/fresh [ProjectedResourceLedgers] when every prefix order is
/// accepted, or `null` when [prefixReplaySucceeded] is already `false` or a
/// newly validated prefix order rejects.
ProjectedResourceLedgers? ensureProjectedResourcePrefixReplay<T, V>({
  required bool? prefixReplaySucceeded,
  required ProjectedResourceLedgers? cachedLedgers,
  required void Function(bool value) setPrefixReplaySucceeded,
  required void Function(ProjectedResourceLedgers ledgers) setCachedLedgers,
  required List<T> existingOrders,
  required V Function() createPrefixValidator,
  required OrderValidationResult Function(V validator, T order) validate,
  required ProjectedResourceLedgers Function(V validator) readLedgers,
}) {
  if (prefixReplaySucceeded == false) {
    return null;
  }
  if (cachedLedgers != null) {
    return cachedLedgers;
  }
  final prefixValidator = createPrefixValidator();
  for (final order in existingOrders) {
    final result = validate(prefixValidator, order);
    if (!result.isAccepted) {
      setPrefixReplaySucceeded(false);
      return null;
    }
  }
  setPrefixReplaySucceeded(true);
  final ledgers = readLedgers(prefixValidator);
  setCachedLedgers(ledgers);
  return ledgers;
}
