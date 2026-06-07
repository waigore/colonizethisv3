import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../diplomacy/diplomacy_resolver.dart';
import 'package:colonizethis_world/src/world/movement.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import '../order_validation_result.dart';
import '../order_visibility.dart';

/// Validates [ArmyMoveOrder]. SPEC/program/orders.md.
class ArmyMoveValidator {
  const ArmyMoveValidator();

  /// Validates the army move.
  ///
  /// [armiesById] (optional) is an O(1) map keyed by `Army.id` used to avoid
  /// per-candidate linear scans of `game.worldState.armies` on hot suggestion
  /// paths (Refs #2394, SPEC/program/order-suggestions.md). When omitted, a
  /// single-pass `firstWhereOrNull`-style scan is used to preserve current
  /// behavior without allocating an intermediate list.
  ///
  /// [factionMembership] (optional) avoids per-candidate `.any()` scans over
  /// players / minors / tribes when classifying destination owners (Refs
  /// #2394).
  OrderValidationResult validate(
    ArmyMoveOrder order,
    Game game,
    String playerId,
    List<DiplomaticOrder> diplomaticOrders,
    PlayerView view,
    MapTopology topology, {
    Map<String, Army>? armiesById,
    DiplomacyFactionMembership? factionMembership,
  }) {
    final army = armiesById != null
        ? armiesById[order.armyId]
        : _firstArmyById(game.worldState.armies, order.armyId);
    if (army == null || army.ownerId != playerId) {
      return OrderValidationResult.rejected('Invalid army move');
    }
    if (army.isHomeArmy) {
      return OrderValidationResult.rejected('Home army cannot leave capital');
    }
    final unitRegion = ProvinceId.regionIdFrom(army.stationedProvinceId);
    final destFullId = resolveToFullProvinceId(
      game.worldState,
      order.destinationProvinceId,
    );
    final destRegion = ProvinceId.regionIdFrom(destFullId);
    final destProvince = game.worldState.tryGetProvince(destFullId);
    final destOwnerId = destProvince?.ownerId;
    final moveToOwnProvince = destOwnerId == playerId;
    if (!moveToOwnProvince && destRegion != unitRegion) {
      return OrderValidationResult.rejected('Invalid army move');
    }
    if (!moveToOwnProvince) {
      final fromLocal = ProvinceId.localIdFrom(army.stationedProvinceId);
      final destLocal = ProvinceId.localIdFrom(destFullId);
      if (!isValidLandMoveInRegion(
        topology,
        unitRegion,
        fromLocal,
        destLocal,
      )) {
        return OrderValidationResult.rejected('Invalid army move');
      }
    }

    if (destOwnerId != null &&
        destOwnerId != playerId &&
        isGreatPower(game, destOwnerId, factionMembership: factionMembership) &&
        !canAttackWithWarOrDeclaring(
          game,
          playerId,
          destOwnerId,
          diplomaticOrders,
        )) {
      return OrderValidationResult.rejected(
        'Must declare war before attacking Great Power province',
      );
    }

    if (destOwnerId != null &&
        destOwnerId != playerId &&
        isMinorOrTribe(game, destOwnerId, factionMembership: factionMembership) &&
        !canAttackWithWarOrDeclaring(
          game,
          playerId,
          destOwnerId,
          diplomaticOrders,
        )) {
      return OrderValidationResult.rejected(
        'Must declare war before attacking Minor Nation or Tribe province',
      );
    }

    if (!moveSourceVisibilityOk(view, unitRegion, army.stationedProvinceId) ||
        !moveDestVisibilityOkForArmy(view, destRegion, destFullId)) {
      return OrderValidationResult.rejected(
        'Source or destination not visible',
      );
    }
    return OrderValidationResult.accepted();
  }
}

bool moveDestVisibilityOkForArmy(
  PlayerView view,
  String destRegion,
  String destFullProvinceId,
) {
  return moveDestVisibilityOk(
    view,
    destRegion,
    destFullProvinceId,
    'musketeers',
  );
}

/// Single-pass first-match army lookup. Used by [ArmyMoveValidator.validate]
/// when no caller-supplied `armiesById` is available. Avoids allocating an
/// intermediate `.where(...).toList()` (Refs #2394).
Army? _firstArmyById(List<Army> armies, String armyId) {
  for (final a in armies) {
    if (a.id == armyId) return a;
  }
  return null;
}
