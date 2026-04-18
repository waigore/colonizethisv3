import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../diplomacy/diplomacy_resolver.dart';
import '../../world/movement.dart';
import '../../world/player_view.dart';
import '../../world/province_lookup.dart';
import '../order_validation_result.dart';
import '../order_visibility.dart';

/// Validates [ArmyMoveOrder]. SPEC/program/orders.md.
class ArmyMoveValidator {
  const ArmyMoveValidator();

  OrderValidationResult validate(
    ArmyMoveOrder order,
    Game game,
    String playerId,
    List<DiplomaticOrder> diplomaticOrders,
    PlayerView view,
    MapTopology topology,
  ) {
    final armyCandidates = game.worldState.armies
        .where((a) => a.id == order.armyId)
        .toList();
    final army = armyCandidates.isEmpty ? null : armyCandidates.first;
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
        isGreatPower(game, destOwnerId) &&
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
        isMinorOrTribe(game, destOwnerId) &&
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
