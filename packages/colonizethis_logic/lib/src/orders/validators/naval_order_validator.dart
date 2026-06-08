import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_resolver.dart';
import 'package:colonizethis_world/src/world/naval.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_world/src/world/topology_helpers.dart';
import '../order_validation_result.dart';

/// Validates naval move and naval mission orders for a single player.
/// SPEC/program/orders.md § Naval orders; SPEC/game/capital-and-connectivity.md § Blockade.
class NavalOrderValidator extends OrderValidator {
  final Game _game;
  final MapTopology _topology;
  final String _playerId;
  final Map<String, Fleet> _fleetById;

  NavalOrderValidator({
    required Game game,
    required MapTopology topology,
    required String playerId,
  }) : _game = game,
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
        if (fleet == null ||
            fleet.ownerId != _playerId ||
            fleet.id == homeFleetId) {
          return OrderValidationResult.rejected(
            fleet == null ? 'Fleet not found' : 'Invalid naval move',
          );
        }

        if (o.isDock) {
          // Dock: fleet must be at sea; current sea zone adjacent to province; province owned by player. SPEC/game/ships-and-naval.md.
          final portProvinceId = o.destinationPortProvinceId!;
          if (!fleet.isAtSea || fleet.seaZoneId == null) {
            return OrderValidationResult.rejected(
              'Dock only allowed when fleet is at sea',
            );
          }
          final fullProvinceId = toFullProvinceId(
            fleet.regionId,
            portProvinceId,
          );
          final province = _game.worldState.tryGetProvince(fullProvinceId);
          if (province == null) {
            return OrderValidationResult.rejected('Port province not found');
          }
          if (province.ownerId != _playerId) {
            return OrderValidationResult.rejected(
              'Can only dock at own province',
            );
          }
          final adjacentSeaZones = seaZoneIdsAdjacentToProvince(
            _topology,
            fullProvinceId,
          );
          final valid = adjacentSeaZones.contains(fleet.seaZoneId);
          return valid
              ? OrderValidationResult.accepted()
              : OrderValidationResult.rejected('Invalid naval move');
        }

        // Move to sea zone: S–S when at sea; P–S undock when in port; [destZone] must be a sea node.
        final destZone = o.destinationSeaZoneId;
        if (destZone == null || destZone.isEmpty) {
          return OrderValidationResult.rejected('Invalid naval move');
        }
        if (!seaZoneNodeIds(_topology).contains(destZone)) {
          return OrderValidationResult.rejected('Invalid naval move');
        }
        if (fleet.isAtSea) {
          final cur = fleet.seaZoneId;
          if (cur == null) {
            return OrderValidationResult.rejected('Invalid naval move');
          }
          final valid =
              cur == destZone || isAdjacentSeaSeaZone(_topology, cur, destZone);
          return valid
              ? OrderValidationResult.accepted()
              : OrderValidationResult.rejected('Invalid naval move');
        }
        final inPortProvinceId = fleet.inPortAtProvinceId;
        if (inPortProvinceId == null) {
          return OrderValidationResult.rejected('Invalid naval move');
        }
        final rl = regionAndLocalProvinceForFleetInPort(
          inPortProvinceId,
          fleet.regionId,
        );
        final provinceNodeId = provinceTopologyNodeId(
          _topology,
          rl.localId,
          rl.regionId,
        );
        if (provinceNodeId == null) {
          return OrderValidationResult.rejected('Invalid naval move');
        }
        final valid = seaZonesAdjacentToProvince(
          _topology,
          provinceNodeId,
        ).contains(destZone);
        return valid
            ? OrderValidationResult.accepted()
            : OrderValidationResult.rejected('Invalid naval move');
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
        var valid =
            fleet != null &&
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
            final province = _game.worldState.tryGetProvince(targetProvinceId);
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

        return valid
            ? OrderValidationResult.accepted()
            : OrderValidationResult.rejected(
                rejectReason ?? 'Invalid naval mission',
              );
      },
    );
  }
}
