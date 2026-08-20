import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../production/commodity_ui_helpers.dart';
import 'train_commodity_cost_dialog_base.dart';
import 'train_peasant_reservation.dart';
import 'train_peasant_reservation_copy.dart';

extension CommodityCostTrainDialogCosts on CommodityCostTrainDialogState {
  int totalTreasuryCost() {
    var total = 0;
    for (final e in commodityCostEntries) {
      total += (counts[e.unitTypeId] ?? 0) * e.buildTreasuryCost;
    }
    return total;
  }

  int totalPeasantCost() {
    var total = 0;
    for (final e in commodityCostEntries) {
      total += counts[e.unitTypeId] ?? 0;
    }
    return total;
  }

  Map<String, int> totalCommodityCosts() {
    final totals = <String, int>{};
    for (final e in commodityCostEntries) {
      final count = counts[e.unitTypeId] ?? 0;
      if (count <= 0) continue;
      for (final input in e.buildInputs.entries) {
        totals[input.key] = (totals[input.key] ?? 0) + (input.value * count);
      }
    }
    return totals;
  }

  TrainOtherFamilyPeasantReservation otherFamilyPeasantReservation() {
    return trainOtherFamilyPeasantReservation(
      currentOrders: widget.currentOrders,
      playerId: widget.humanPlayerId,
      capitalProvinceId: player?.capitalProvinceId,
      managedUnitTypeIds: unitTypeIds.toSet(),
      managedOrdersAreMilitary: ordersAreMilitary,
    );
  }

  /// Peasants free for this dialog before local stepper counts.
  int availablePeasants() => trainAvailablePeasants(
    poolPeasants: peasants,
    otherFamily: otherFamilyPeasantReservation(),
  );

  int remainingTreasury() => treasury - totalTreasuryCost();

  /// Remaining = available (pool − other families) − this dialog's counts.
  int remainingPeasants() => availablePeasants() - totalPeasantCost();

  int remainingCommodity(String commodityId, Map<String, int> committed) =>
      stockpileQty(commodityId) - (committed[commodityId] ?? 0);

  String? peasantsPromisedGist(AppLocalizations l10n) =>
      trainPeasantsPromisedGist(l10n, otherFamilyPeasantReservation());

  String peasantsPromisedDetails(AppLocalizations l10n) =>
      trainPeasantsPromisedDetails(l10n, otherFamilyPeasantReservation());

  String? commodityCostDeficitHint(AppLocalizations l10n) {
    final deficits = <String>[];
    if (totalTreasuryCost() > treasury) deficits.add('Treasury');
    if (totalPeasantCost() > availablePeasants()) deficits.add('Peasants');
    final totalComms = totalCommodityCosts();
    for (final e in totalComms.entries) {
      if (e.value > stockpileQty(e.key)) {
        deficits.add(commodityDisplayName(l10n, e.key));
      }
    }
    if (deficits.isEmpty) return null;
    return deficits.map((name) => '$name low').join(', ');
  }
}
