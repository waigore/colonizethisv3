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
