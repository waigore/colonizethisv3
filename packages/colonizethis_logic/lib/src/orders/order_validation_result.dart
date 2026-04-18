/// Validation result for one order. First invalid + all subsequent rejected.
/// Used by OrderEngine and extracted validators (MoveValidator, etc.).
/// SPEC/program/order-engine.md.
library;

enum OrderValidationStatus { accepted, rejected }

class OrderValidationResult {
  const OrderValidationResult({required this.status, this.reason});

  final OrderValidationStatus status;
  final String? reason;

  bool get isAccepted => status == OrderValidationStatus.accepted;

  /// Factory for rejected result with optional reason.
  factory OrderValidationResult.rejected(String reason) =>
      OrderValidationResult(
        status: OrderValidationStatus.rejected,
        reason: reason,
      );

  /// Factory for accepted result.
  factory OrderValidationResult.accepted() => _accepted;

  static const _accepted = OrderValidationResult(
    status: OrderValidationStatus.accepted,
  );
}

/// Shared constant result used when a previous order in the sequence
/// has already been rejected and all subsequent orders must be rejected.
const OrderValidationResult previousInvalidOrderResult = OrderValidationResult(
  status: OrderValidationStatus.rejected,
  reason: 'Previous invalid',
);

/// Base helper for validators that short-circuit after the first rejected order.
abstract class OrderValidator {
  const OrderValidator();

  OrderValidationResult shortCircuitIfPreviousRejected({
    required bool previousRejected,
    required OrderValidationResult Function() body,
  }) {
    return previousRejected ? previousInvalidOrderResult : body();
  }

  ({OrderValidationResult result, int treasury})
  shortCircuitIfPreviousRejectedWithTreasury({
    required bool previousRejected,
    required int currentTreasury,
    required ({OrderValidationResult result, int treasury}) Function() body,
  }) {
    if (previousRejected) {
      return (result: previousInvalidOrderResult, treasury: currentTreasury);
    }
    return body();
  }
}

/// Helper for validators that use a [previousRejected] flag.
/// If [previousRejected] is true, returns [previousInvalidOrderResult] and skips [body].
/// Otherwise runs [body] and returns its [OrderValidationResult].
OrderValidationResult shortCircuitIfPreviousRejected({
  required bool previousRejected,
  required OrderValidationResult Function() body,
}) {
  if (previousRejected) {
    return previousInvalidOrderResult;
  }
  return body();
}

/// Like [shortCircuitIfPreviousRejected] for validators that also return updated treasury.
/// When [previousRejected], returns (previousInvalidOrderResult, currentTreasury); else [body]().
({OrderValidationResult result, int treasury})
shortCircuitIfPreviousRejectedWithTreasury({
  required bool previousRejected,
  required int currentTreasury,
  required ({OrderValidationResult result, int treasury}) Function() body,
}) {
  if (previousRejected) {
    return (result: previousInvalidOrderResult, treasury: currentTreasury);
  }
  return body();
}
