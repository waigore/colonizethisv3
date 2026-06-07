import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../diplomacy/diplomacy_resolver.dart';
import 'package:colonizethis_world/src/world/civilian_tile_occupancy.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import '../order_resolution_context.dart';
import '../order_validation_result.dart';
import '../order_visibility.dart';

/// Validates move orders. SPEC/program/orders.md § Move orders.
/// Used by OrderEngine in validatePlayerOrdersWithContext.
///
/// Accepts the canonical [OrderResolutionContext] record so the per-pass
/// `view` + `unitsById` snapshot is reused across many candidate probes
/// without rebuilding the unit map or [PlayerView] (Refs #2836 AC 3;
/// SPEC/program/logic-validator-units-params.md).
class MoveValidator extends OrderValidator {
  const MoveValidator();

  OrderValidationResult validate(
    MoveOrder order,
    Game game,
    String playerId,
    OrderResolutionContext context,
    List<DiplomaticOrder> diplomaticOrders,
    MapTopology topology, {
    required bool previousRejected,
    DiplomacyFactionMembership? factionMembership,
  }) {
    return shortCircuitIfPreviousRejected(
      previousRejected: previousRejected,
      body: () {
        final unit = context.unitsById[order.unitId];
        if (unit == null || unit.ownerId != playerId) {
          return OrderValidationResult.rejected('Invalid move');
        }
        if (isMilitaryUnit(unit.type)) {
          return OrderValidationResult.rejected(
            'Military units move with armies; use army move',
          );
        }

        final destTile = order.destinationTileKey;
        if (destTile.isEmpty) {
          return OrderValidationResult.rejected('Invalid move');
        }
        if (!isLandTileKeyForGame(game, destTile)) {
          return OrderValidationResult.rejected('Invalid move');
        }

        final unitRegion = unit.tileKey != null && unit.tileKey!.isNotEmpty
            ? Unit.requireRegionIdFromTileKey(unit.tileKey)
            : ProvinceId.regionIdFrom(
                resolveToFullProvinceId(
                  game.worldState,
                  unit.locationProvinceId,
                ),
              );

        final view = context.view;
        if (!moveSourceVisibilityOk(
              view,
              unitRegion,
              unit.locationProvinceId,
            ) ||
            !moveDestinationTileVisibilityOk(view, destTile)) {
          return OrderValidationResult.rejected(
            'Source or destination not visible',
          );
        }

        if (!civilianMayOccupyLandTileKey(
          game: game,
          playerId: playerId,
          unitType: unit.type,
          destinationTileKey: destTile,
          factionMembership: factionMembership,
        )) {
          return OrderValidationResult.rejected('Invalid move');
        }

        return OrderValidationResult.accepted();
      },
    );
  }
}
