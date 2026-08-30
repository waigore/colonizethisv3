// Peasant-reservation ledger for commodity-cost train dialogs (military/naval).
// SPEC/ui/train-military-dialog.md, SPEC/ui/train-naval-dialog.md,
// SPEC/game/workers-and-population.md § Peasant reservation.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Family breakdown of peasants already promised outside this dialog's
/// managed [BuildUnitOrder] set (those live in local stepper counts).
class TrainOtherFamilyPeasantReservation {
  const TrainOtherFamilyPeasantReservation({
    required this.workerTraining,
    required this.ships,
    required this.regiments,
  });

  /// Queued trained-tier [RecruitWorkerOrder]s that consume a peasant.
  final int workerTraining;

  /// Queued naval [BuildUnitOrder]s not managed by this dialog.
  final int ships;

  /// Queued military [BuildUnitOrder]s not managed by this dialog.
  final int regiments;

  int get total => workerTraining + ships + regiments;

  bool get isEmpty => total <= 0;
}

/// Whether [order] is in this train dialog's managed replace set (same rules
/// as [mergeTrainMilitaryOrdersForPlayer] / [mergeTrainNavalOrdersForPlayer]).
bool isTrainDialogManagedBuildOrder({
  required BuildUnitOrder order,
  required String? capitalProvinceId,
  required Set<String> managedUnitTypeIds,
  required bool managedOrdersAreMilitary,
}) {
  if (order.isMilitary != managedOrdersAreMilitary) return false;
  if (!managedUnitTypeIds.contains(order.unitType)) return false;
  if (capitalProvinceId == null) return false;
  return order.spawnProvinceId == capitalProvinceId;
}

/// Other-family peasant reservation for a commodity-cost train dialog.
///
/// Counts every pending peasant consume from queued worker trains and from
/// military/naval builds **except** this dialog's managed capital orders
/// (those are already reflected in local [counts]). Civilian builds never
/// consume peasants.
TrainOtherFamilyPeasantReservation trainOtherFamilyPeasantReservation({
  required Orders currentOrders,
  required String playerId,
  required String? capitalProvinceId,
  required Set<String> managedUnitTypeIds,
  required bool managedOrdersAreMilitary,
}) {
  var workerTraining = 0;
  final recruits =
      currentOrders.recruitWorkerOrdersByPlayerId[playerId] ??
      const <RecruitWorkerOrder>[];
  for (final order in recruits) {
    if (WorkerActionEconomyCatalog.forTier(order.targetTier).consumesPeasant) {
      workerTraining += 1;
    }
  }

  var ships = 0;
  var regiments = 0;
  final builds =
      currentOrders.buildUnitOrdersByPlayerId[playerId] ??
      const <BuildUnitOrder>[];
  for (final order in builds) {
    if (isTrainDialogManagedBuildOrder(
      order: order,
      capitalProvinceId: capitalProvinceId,
      managedUnitTypeIds: managedUnitTypeIds,
      managedOrdersAreMilitary: managedOrdersAreMilitary,
    )) {
      continue;
    }
    final category = buildUnitCategoryForUnitType(order.unitType);
    if (category == BuildUnitCategory.naval) {
      ships += 1;
    } else if (category == BuildUnitCategory.military) {
      regiments += 1;
    }
  }

  return TrainOtherFamilyPeasantReservation(
    workerTraining: workerTraining,
    ships: ships,
    regiments: regiments,
  );
}

/// Peasants available for this dialog's steppers before local counts:
/// `pool.peasants − other-family reservation` (clamped at 0).
int trainAvailablePeasants({
  required int poolPeasants,
  required TrainOtherFamilyPeasantReservation otherFamily,
}) {
  final available = poolPeasants - otherFamily.total;
  return available < 0 ? 0 : available;
}
