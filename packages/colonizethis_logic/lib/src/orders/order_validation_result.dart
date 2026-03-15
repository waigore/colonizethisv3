/// Validation result for one order. First invalid + all subsequent rejected.
/// Used by OrderEngine and extracted validators (MoveValidator, etc.).
/// SPEC/program/order-engine.md.

enum OrderValidationStatus { accepted, rejected }

class OrderValidationResult {
  const OrderValidationResult({
    required this.status,
    this.reason,
  });

  final OrderValidationStatus status;
  final String? reason;

  bool get isAccepted => status == OrderValidationStatus.accepted;

  /// Factory for rejected result with optional reason.
  factory OrderValidationResult.rejected(String reason) =>
      OrderValidationResult(status: OrderValidationStatus.rejected, reason: reason);

  /// Factory for accepted result.
  factory OrderValidationResult.accepted() => _accepted;

  static const _accepted =
      OrderValidationResult(status: OrderValidationStatus.accepted);
}

/// Shared constant result used when a previous order in the sequence
/// has already been rejected and all subsequent orders must be rejected.
const OrderValidationResult previousInvalidOrderResult = OrderValidationResult(
  status: OrderValidationStatus.rejected,
  reason: 'Previous invalid',
);

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
