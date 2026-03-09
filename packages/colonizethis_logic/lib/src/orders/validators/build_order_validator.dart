import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../economy/economy_production.dart';
import '../order_validation_result.dart';

/// Validates build unit orders for a single player in submission order.
/// Mutates internal economy state (workers, stockpile, treasury) when an order
/// is accepted. SPEC/program/orders.md § Build orders.
class BuildOrderValidator {
  final Game _game;
  final Player _player;

  WorkerPool _workers;
  Stockpile _stockpile;
  int _treasury;

  BuildOrderValidator({
    required Game game,
    required Player player,
  })  : _game = game,
        _player = player,
        _workers = player.workerPool,
        _stockpile = player.stockpile,
        _treasury = player.treasury;

  WorkerPool get workers => _workers;
  Stockpile get stockpile => _stockpile;
  int get treasury => _treasury;

  /// Validates one [BuildUnitOrder]. When accepted, deducts cost from internal
  /// workers/stockpile/treasury. Caller should sync these back after the build loop.
  OrderValidationResult validate(
    BuildUnitOrder o, {
    required bool previousRejected,
  }) {
    if (previousRejected) {
      return const OrderValidationResult(
        status: OrderValidationStatus.rejected,
        reason: 'Previous invalid',
      );
    }

    if (_player.capitalProvinceId == null) {
      return const OrderValidationResult(
        status: OrderValidationStatus.rejected,
        reason: 'No capital to spawn unit',
      );
    }

    final category = buildUnitCategoryForUnitType(o.unitType);
    switch (category) {
      case BuildUnitCategory.civilian:
        final econ = CivilianEconomyCatalog.byId[o.unitType];
        if (econ == null) {
          return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Insufficient resources',
          );
        }
        final unlockingTechId = unlockingTechByCivilianId[o.unitType];
        if (unlockingTechId != null &&
            (_player.techUnlocked?[unlockingTechId] != true)) {
          return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Insufficient resources',
          );
        }
        if (_treasury < econ.buildTreasuryCost) {
          return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Insufficient treasury',
          );
        }
        for (final e in econ.buildInputs.entries) {
          if (_stockpile.quantityOf(e.key) < e.value) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Insufficient materials',
            );
          }
        }
        _treasury -= econ.buildTreasuryCost;
        for (final e in econ.buildInputs.entries) {
          _stockpile = _stockpile.applyDelta(e.key, -e.value);
        }
        return const OrderValidationResult(
          status: OrderValidationStatus.accepted,
        );

      case BuildUnitCategory.military:
        final econ = RegimentEconomyCatalog.byId[o.unitType];
        if (econ == null) {
          return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Insufficient resources',
          );
        }
        final regimentUnlockTech = unlockingTechByRegimentId[o.unitType];
        if (regimentUnlockTech != null &&
            (_player.techUnlocked?[regimentUnlockTech] != true)) {
          return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Insufficient resources',
          );
        }
        if (_workers.peasants <= 0) {
          return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Insufficient resources',
          );
        }
        if (_treasury < econ.buildTreasuryCost) {
          return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Insufficient treasury',
          );
        }
        for (final e in econ.buildInputs.entries) {
          if (_stockpile.quantityOf(e.key) < e.value) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Insufficient materials',
            );
          }
        }
        _treasury -= econ.buildTreasuryCost;
        for (final e in econ.buildInputs.entries) {
          _stockpile = _stockpile.applyDelta(e.key, -e.value);
        }
        _workers = _workers.copyWith(peasants: _workers.peasants - 1);
        return const OrderValidationResult(
          status: OrderValidationStatus.accepted,
        );

      case BuildUnitCategory.naval:
        final shipEcon = ShipEconomyCatalog.byId[o.unitType];
        if (shipEcon == null) {
          return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Insufficient resources',
          );
        }
        final shipUnlockTech = unlockingTechByShipId[o.unitType];
        if (shipUnlockTech != null &&
            (_player.techUnlocked?[shipUnlockTech] != true)) {
          return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Insufficient tech',
          );
        }
        if (_treasury < shipEcon.buildTreasuryCost) {
          return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Insufficient treasury',
          );
        }
        for (final e in shipEcon.buildInputs.entries) {
          if (_stockpile.quantityOf(e.key) < e.value) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Insufficient materials',
            );
          }
        }
        _treasury -= shipEcon.buildTreasuryCost;
        for (final e in shipEcon.buildInputs.entries) {
          _stockpile = _stockpile.applyDelta(e.key, -e.value);
        }
        return const OrderValidationResult(
          status: OrderValidationStatus.accepted,
        );

      case BuildUnitCategory.unknown:
        return const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Insufficient resources',
        );
    }
  }
}
