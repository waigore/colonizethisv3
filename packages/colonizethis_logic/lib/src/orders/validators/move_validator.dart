import 'package:colonizethis_models/colonizethis_models.dart';
import '../../diplomacy/diplomacy_resolver.dart';
import '../order_engine.dart';
import '../order_visibility.dart';

/// Validates move orders. SPEC/program/orders.md § Move orders.
class MoveValidator {
  const MoveValidator();

  OrderValidationResult validate(
    MoveOrder order,
    Game game,
    String playerId,
    Map<String, Unit> unitsById,
    List<DiplomaticOrder> diplomaticOrders,
    PlayerView view,
    MapTopology topology,
  ) {
    final unit = unitsById[order.unitId];
    if (unit == null || unit.ownerId != playerId) {
      return const OrderValidationResult(
          status: OrderValidationStatus.rejected, reason: 'Invalid move');
    }

    final unitRegion = unit.tileKey != null && unit.tileKey!.isNotEmpty
        ? Unit.requireRegionIdFromTileKey(unit.tileKey)
        : ProvinceId.regionIdFrom(
            resolveToFullProvinceId(game.worldState, unit.provinceId));
    final destFullId =
        resolveToFullProvinceId(game.worldState, order.destinationProvinceId);
    final destRegion = ProvinceId.regionIdFrom(destFullId);
    final destProvince = tryGetProvince(game.worldState, destFullId);
    final destOwnerId = destProvince?.ownerId;
    final moveToOwnProvince = destOwnerId == playerId;

    if (!moveToOwnProvince && destRegion != unitRegion) {
      return const OrderValidationResult(
          status: OrderValidationStatus.rejected, reason: 'Invalid move');
    }

    if (!moveToOwnProvince) {
      final unitLocalId = ProvinceId.localIdFrom(unit.locationProvinceId);
      final destLocalId = ProvinceId.localIdFrom(destFullId);
      if (!isValidLandMoveInRegion(
          topology, unitRegion, unitLocalId, destLocalId)) {
        return const OrderValidationResult(
            status: OrderValidationStatus.rejected, reason: 'Invalid move');
      }
    }

    // War declaration checks...
    final rel = getRelation(game, playerId, destOwnerId ?? '');
    final atWar = rel?.atWar ?? false;
    final declaringWarThisTurn = diplomaticOrders.any((o) =>
        o.type == DiplomaticOrderType.declareWar &&
        o.targetFactionId == destOwnerId);

    if (destOwnerId != null &&
        destOwnerId != playerId &&
        !_ownerIsMinorOrTribe(game, destOwnerId) &&
        !atWar &&
        !declaringWarThisTurn) {
      return const OrderValidationResult(
        status: OrderValidationStatus.rejected,
        reason: 'Must declare war before attacking Great Power province',
      );
    }

    if (!moveSourceVisibilityOk(view, unitRegion, unit.locationProvinceId) ||
        !moveDestVisibilityOk(
            view, destRegion, order.destinationProvinceId, unit.type)) {
      return const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Source or destination not visible');
    }
    return const OrderValidationResult(status: OrderValidationStatus.accepted);
  }

  bool _ownerIsMinorOrTribe(Game game, String ownerId) {
    return game.minorNations.any((m) => m.id == ownerId) ||
        game.tribes.any((t) => t.id == ownerId);
  }
}
