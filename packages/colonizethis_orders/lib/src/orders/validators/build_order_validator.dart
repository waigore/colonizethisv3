import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_economy/colonizethis_economy.dart';
import '../build_spawn_province.dart';

import 'stateful_validator.dart';

/// Validates build unit orders for a single player in submission order.
/// Mutates internal economy state (workers, stockpile, treasury) when an order
/// is accepted. SPEC/program/orders.md § Build orders.
class BuildOrderValidator extends StatefulValidator {
  final Game _game;
  final Player _player;

  BuildOrderValidator({required Game game, required Player player})
    : _game = game,
      _player = player,
      super(
        stockpileState: player.stockpile,
        treasuryState: player.treasury,
        workerPoolState: player.workerPool,
      );

  /// Validates further [BuildUnitOrder]s from an economy snapshot produced by
  /// replaying accepted build orders in submission order (Refs #2394).
  BuildOrderValidator.withProjectedEconomy({
    required Game game,
    required Player player,
    required Stockpile stockpile,
    required int treasury,
    required WorkerPool workerPool,
  }) : _game = game,
       _player = player,
       super.withProjectedEconomy(
         stockpile: stockpile,
         treasury: treasury,
         workerPool: workerPool,
       );

  WorkerPool get workers => workerPoolState;
  Stockpile get stockpile => stockpileState;
  int get treasury => treasuryState;

  /// Validates one [BuildUnitOrder]. When accepted, deducts cost from internal
  /// workers/stockpile/treasury. Caller should sync these back after the build loop.
  OrderValidationResult validate(
    BuildUnitOrder o, {
    required bool previousRejected,
  }) {
    return shortCircuitIfPreviousRejected(
      previousRejected: previousRejected,
      body: () {
        final category = buildUnitCategoryForUnitType(o.unitType);
        if (category == BuildUnitCategory.civilian) {
          final civilianTileKey = resolveCivilianSpawnTileKey(
            player: _player,
            worldState: _game.worldState,
          );
          if (civilianTileKey == null) {
            return OrderValidationResult.rejected(
              kCivilianCapitalTileMissingReason,
            );
          }
        }

        final resolvedSpawnProvinceId = resolveBuildSpawnProvinceId(
          player: _player,
          worldState: _game.worldState,
          order: o,
        );
        if (resolvedSpawnProvinceId == null) {
          return OrderValidationResult.rejected('No capital to spawn unit');
        }

        final check = ProjectedCostEngine.canAffordBuildOrder(
          _player,
          o,
          workerPoolState,
          stockpileState,
          treasuryState,
        );
        return applyCostIfAffordable(
          check: check,
          applyDeduction: () {
            final after = ProjectedCostEngine.applyBuildOrderCostDeduction(
              _player,
              o,
              workerPoolState,
              stockpileState,
              treasuryState,
            );
            workerPoolState = after.workers;
            stockpileState = after.stockpile;
            treasuryState = after.treasury;
          },
        );
      },
    );
  }
}
