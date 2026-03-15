import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../diplomacy/diplomacy_resolver.dart';
import '../../world/naval.dart';
import '../../world/province_lookup.dart';
import '../order_validation_result.dart';

/// Validates naval move and naval mission orders for a single player.
/// SPEC/program/orders.md § Naval orders; SPEC/game/capital-and-connectivity.md § Blockade.
class NavalOrderValidator {
  final Game _game;
  final MapTopology _topology;
  final String _playerId;
  final Map<String, Fleet> _fleetById;

  NavalOrderValidator({
    required Game game,
    required MapTopology topology,
    required String playerId,
  })  : _game = game,
        _topology = topology,
        _playerId = playerId,
        _fleetById = {for (final f in game.worldState.fleets) f.id: f};

  /// Validates one [NavalMoveOrder]. Home fleet cannot move; move must be to adjacent sea zone (or undock from port).
  OrderValidationResult validateNavalMove(
    NavalMoveOrder o, {
    required bool previousRejected,
  }) {
    return shortCircuitIfPreviousRejected(
      previousRejected: previousRejected,
      body: () {
        final fleet = _fleetById[o.fleetId];
        final homeFleetId = homeFleetIdFor(_playerId);
        if (fleet == null || fleet.ownerId != _playerId || fleet.id == homeFleetId) {
          return OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: fleet == null ? 'Fleet not found' : 'Invalid naval move',
          );
        }

        if (o.isDock) {
          // Dock: fleet must be at sea; current sea zone adjacent to province; province owned by player. SPEC/game/ships-and-naval.md.
          final portProvinceId = o.destinationPortProvinceId!;
          if (!fleet.isAtSea || fleet.seaZoneId == null) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Dock only allowed when fleet is at sea',
            );
          }
          final fullProvinceId = toFullProvinceId(fleet.regionId, portProvinceId);
          final province = tryGetProvince(_game.worldState, fullProvinceId);
          if (province == null) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Port province not found',
            );
          }
          if (province.ownerId != _playerId) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Can only dock at own province',
            );
          }
          final adjacentSeaZones = seaZoneIdsAdjacentToProvince(_topology, fullProvinceId);
          final valid = adjacentSeaZones.contains(fleet.seaZoneId);
          return OrderValidationResult(
            status: valid ? OrderValidationStatus.accepted : OrderValidationStatus.rejected,
            reason: valid ? null : 'Invalid naval move',
          );
        }

        // Move to sea zone: destination must be adjacent.
        final String? currentZone;
        if (fleet.isAtSea) {
          currentZone = fleet.seaZoneId;
        } else {
          final inPortProvinceId = fleet.inPortAtProvinceId;
          if (inPortProvinceId == null) {
            return const OrderValidationResult(
                status: OrderValidationStatus.rejected, reason: 'Invalid naval move');
          }
          final parts = inPortProvinceId.split('|');
          final regionId = parts.isNotEmpty ? parts.first : fleet.regionId;
          final localId = parts.length > 1 ? parts.sublist(1).join('|') : inPortProvinceId;
          currentZone = seaZoneIdForProvince(_topology, localId, regionId: regionId);
        }
        final destZone = o.destinationSeaZoneId;
        final valid = currentZone != null &&
            destZone != null &&
            destZone.isNotEmpty &&
            (currentZone == destZone || isAdjacentSeaZone(_topology, currentZone, destZone));
        return OrderValidationResult(
          status: valid ? OrderValidationStatus.accepted : OrderValidationStatus.rejected,
          reason: valid ? null : 'Invalid naval move',
        );
      },
    );
  }

  /// Validates one [NavalMissionOrder]. Blockade requires a target province and war.
  OrderValidationResult validateNavalMission(
    NavalMissionOrder o, {
    required bool previousRejected,
  }) {
    return shortCircuitIfPreviousRejected(
      previousRejected: previousRejected,
      body: () {
        final fleet = _fleetById[o.fleetId];
        final homeFleetId = homeFleetIdFor(_playerId);
        var valid = fleet != null &&
            fleet.ownerId == _playerId &&
            (o.mission == 'join_home_fleet' || fleet.id != homeFleetId);
        String? rejectReason = valid
            ? null
            : (fleet == null ? 'Fleet not found' : 'Fleet not owned by player');

        if (valid && o.mission == 'blockade') {
          final targetProvinceId = o.targetProvinceId;
          if (targetProvinceId == null ||
              targetProvinceId.isEmpty ||
              !ProvinceId.isPrefixed(targetProvinceId)) {
            valid = false;
            rejectReason = 'Blockade requires a target province';
          } else {
            final province = tryGetProvince(_game.worldState, targetProvinceId);
            final ownerId = province?.ownerId;
            if (province == null || ownerId == null || ownerId.isEmpty) {
              valid = false;
              rejectReason = 'Blockade target province not found or unowned';
            } else if (ownerId == _playerId) {
              valid = false;
              rejectReason = 'Cannot blockade own province';
            } else {
              final rel = getRelation(_game, _playerId, ownerId);
              if (rel?.atWar != true) {
                valid = false;
                rejectReason = 'Blockade only allowed against nations at war';
              }
            }
          }
        }

        return OrderValidationResult(
          status: valid
              ? OrderValidationStatus.accepted
              : OrderValidationStatus.rejected,
          reason: rejectReason,
        );
      },
    );
  }
}
