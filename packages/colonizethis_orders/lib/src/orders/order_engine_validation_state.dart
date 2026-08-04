import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_validation_result.dart';

/// Mutable state threaded through [runOrderValidationPhases].
/// Holds the running rejected flag, treasury, stockpile, worker pool, and
/// the accumulated [OrderValidationResult] list. Existing only inside
/// [OrderEngine.validatePlayerOrdersWithContext]'s call stack.
class OrderValidationRunState {
  OrderValidationRunState({
    required this.results,
    required this.stockpile,
    required this.treasury,
    required this.workerPool,
  });

  final List<OrderValidationResult> results;
  bool rejected = false;
  Stockpile stockpile;
  int treasury;
  WorkerPool workerPool;
}
