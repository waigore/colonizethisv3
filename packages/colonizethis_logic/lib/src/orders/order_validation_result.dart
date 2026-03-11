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
}

/// Shared constant result used when a previous order in the sequence
/// has already been rejected and all subsequent orders must be rejected.
const OrderValidationResult previousInvalidOrderResult = OrderValidationResult(
  status: OrderValidationStatus.rejected,
  reason: 'Previous invalid',
);
