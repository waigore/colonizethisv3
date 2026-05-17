import 'package:colonizethis_models/colonizethis_models.dart';

import '../order_validation_result.dart';

/// Base for validators that mutate economy fields while validating a player's
/// orders in submission order. [stockpileState] and [workerPoolState] are
/// carried for [WorkOrderValidator] / [BuildOrderValidator]; diplomatic
/// validation mutates [treasuryState] only. SPEC/program/orders.md.
abstract class StatefulValidator extends OrderValidator {
  StatefulValidator({
    required this.stockpileState,
    required this.treasuryState,
    required this.workerPoolState,
  }) : super();

  Stockpile stockpileState;
  int treasuryState;
  WorkerPool workerPoolState;
}
