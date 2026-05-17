import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../diplomacy/diplomacy_resolver.dart';
import '../../world/civilian_tile_occupancy.dart';
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
    MapTopology topology, {
    required bool previousRejected,
    DiplomacyFactionMembership? factionMembership,
  }) {
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
                resolveToFullProvinceId(game.worldState, unit.locationProvinceId),
              );

        if (!moveSourceVisibilityOk(view, unitRegion, unit.locationProvinceId) ||
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
