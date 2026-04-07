import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../diplomacy/diplomacy_relation_lookup.dart';
import '../../diplomacy/diplomacy_resolver.dart';
import '../../world/movement.dart';
import '../../world/player_view.dart';
import '../../world/province_lookup.dart';
import '../order_validation_result.dart';
import '../order_visibility.dart';

/// Validates move orders. SPEC/program/orders.md § Move orders.
/// Used by OrderEngine in validatePlayerOrdersWithContext.
class MoveValidator extends OrderValidator {
  const MoveValidator();

  OrderValidationResult validate(
    MoveOrder order,
    Game game,
    String playerId,
    Map<String, Unit> unitsById,
    List<DiplomaticOrder> diplomaticOrders,
    PlayerView view,
    MapTopology topology,
    {required bool previousRejected}
  ) {
    return shortCircuitIfPreviousRejected(
      previousRejected: previousRejected,
      body: () {
        final unit = unitsById[order.unitId];
        if (unit == null || unit.ownerId != playerId) {
          return OrderValidationResult.rejected('Invalid move');
        }
        if (isMilitaryUnit(unit.type)) {
          return OrderValidationResult.rejected(
            'Military units move with armies; use army move',
          );
        }
        final unitRegion = unit.tileKey != null && unit.tileKey!.isNotEmpty
            ? Unit.requireRegionIdFromTileKey(unit.tileKey)
            : ProvinceId.regionIdFrom(
                resolveToFullProvinceId(game.worldState, unit.locationProvinceId),
              );
        final destFullId = resolveToFullProvinceId(
          game.worldState,
          order.destinationProvinceId,
        );
        final destRegion = ProvinceId.regionIdFrom(destFullId);
        final destProvince = game.worldState.tryGetProvince(destFullId);
        final destOwnerId = destProvince?.ownerId;
        // Movement within own provinces: always allowed. SPEC/program/movement.md.
        final moveToOwnProvince = destOwnerId == playerId;
        if (!moveToOwnProvince && destRegion != unitRegion) {
          return OrderValidationResult.rejected('Invalid move');
        }
        if (!moveToOwnProvince) {
          final unitLocalId = ProvinceId.localIdFrom(unit.locationProvinceId);
          final destLocalId = ProvinceId.localIdFrom(destFullId);
          if (!isValidLandMoveInRegion(
            topology,
            unitRegion,
            unitLocalId,
            destLocalId,
          )) {
            return OrderValidationResult.rejected('Invalid move');
          }
        }

        // Civilian vs foreign territory
        if (!isMilitaryUnit(unit.type) &&
            destOwnerId != null &&
            destOwnerId != playerId) {
          if (isGreatPower(game, destOwnerId) && !isSpyUnit(unit.type)) {
            return OrderValidationResult.rejected(
              'Civilian cannot enter other Great Power territory',
            );
          }
          if (isMinorOrTribe(game, destOwnerId) &&
              !isExplorerUnit(unit.type) &&
              !isMerchantUnit(unit.type) &&
              !isSpyUnit(unit.type)) {
            return OrderValidationResult.rejected(
              'Civilian cannot enter Minor/Tribe territory',
            );
          }
        }

        // Attack validation: GP province requires war or same-turn declareWar.
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

        // Attack validation: Minor/Tribe province requires war for military units.
        if (destOwnerId != null &&
            destOwnerId != playerId &&
            isMinorOrTribe(game, destOwnerId) &&
            isMilitaryUnit(unit.type) &&
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

        if (!moveSourceVisibilityOk(view, unitRegion, unit.locationProvinceId) ||
            !moveDestVisibilityOk(
              view,
              destRegion,
              order.destinationProvinceId,
              unit.type,
            )) {
          return OrderValidationResult.rejected(
            'Source or destination not visible',
          );
        }
        return OrderValidationResult.accepted();
      },
    );
  }
}
