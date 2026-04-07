import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../economy/build_cost.dart';
import '../build_spawn_province.dart';
import '../order_validation_result.dart';

/// Validates build unit orders for a single player in submission order.
/// Mutates internal economy state (workers, stockpile, treasury) when an order
/// is accepted. SPEC/program/orders.md § Build orders.
class BuildOrderValidator extends OrderValidator {
  final Game _game;
  final Player _player;

  WorkerPool _workers;
  Stockpile _stockpile;
  int _treasury;

  BuildOrderValidator({required Game game, required Player player})
    : _game = game,
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

        final check = canAffordBuild(
          _player,
          o,
          _workers,
          _stockpile,
          _treasury,
        );
        if (!check.canAfford) {
          return OrderValidationResult.rejected(
            check.reason ?? 'Insufficient resources',
          );
        }

        final after = applyBuildCostDeduction(
          _player,
          o,
          _workers,
          _stockpile,
          _treasury,
        );
        _workers = after.workers;
        _stockpile = after.stockpile;
        _treasury = after.treasury;
        return OrderValidationResult.accepted();
      },
    );
  }
}
