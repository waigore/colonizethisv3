import 'package:colonizethis_models/colonizethis_models.dart';

/// Removes the pending civilian work order at [index] for [playerId] in this
/// turn's draft [orders]. No-op if the list is missing or [index] is out of
/// range. SPEC/program/orders.md.
Orders removePendingWorkOrderAt(
  Orders orders,
  String playerId,
  int index,
) {
  final list = orders.workOrdersByPlayerId[playerId];
  if (list == null || index < 0 || index >= list.length) {
    return orders;
  }
  final next = List<WorkOrder>.from(list)..removeAt(index);
  return orders.copyWith(
    workOrdersByPlayerId: {
      ...orders.workOrdersByPlayerId,
      playerId: next,
    },
  );
}
