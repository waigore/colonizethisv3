import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

Game applyImplicitBundledCivilianWorkOrderMoves(
  Game game,
  MapTopology topology,
  Orders orders, {
  BundledWorkMoveTraceCallback? onBundledWorkMoveTrace,
}) {
  var state = game;
  final workByPlayerId = orders.workOrdersByPlayerId;
  if (workByPlayerId.isEmpty) {
    return state;
  }

  final unitById = Map<String, Unit>.from(state.worldState.allUnitsById);
  final viewByPlayerId = <String, PlayerView>{};
  for (final entry in workByPlayerId.entries) {
    final playerId = entry.key;
    final diplomatic =
        orders.diplomaticOrdersByPlayerId[playerId] ??
        const <DiplomaticOrder>[];
    var view = viewByPlayerId.putIfAbsent(
      playerId,
      () => buildPlayerView(state, topology, playerId),
    );
    for (final workOrder in entry.value) {
      final unit = unitById[workOrder.unitId];
      if (unit == null || unit.ownerId != playerId) {
        onBundledWorkMoveTrace?.call(
          playerId: playerId,
          order: workOrder,
          applied: false,
          ignoreReason: 'missing_or_foreign_unit',
        );
        continue;
      }
      if (!civilianBundledWorkNeedsProvinceMoveLeg(state, unit, workOrder)) {
        onBundledWorkMoveTrace?.call(
          playerId: playerId,
          order: workOrder,
          applied: false,
          ignoreReason: 'move_leg_not_required',
        );
        continue;
      }
      final destination = executionProvinceFullIdFromWorkOrder(
        state,
        workOrder,
      );
      if (destination == null) {
        onBundledWorkMoveTrace?.call(
          playerId: playerId,
          order: workOrder,
          applied: false,
          ignoreReason: 'destination_unresolved',
        );
        continue;
      }
      final resolution = orderResolutionContextFromView(
        view,
        state,
        unitsById: unitById,
      );
      final destinationTile = firstLegalBundledEntryTileKeyInProvince(
        game: state,
        topology: topology,
        playerId: playerId,
        unit: unit,
        destProvinceFullId: destination,
        preferredTargetTileKey: workOrder.targetTileKey,
        resolution: resolution,
        diplomaticOrders: diplomatic,
      );
      if (destinationTile == null) {
        onBundledWorkMoveTrace?.call(
          playerId: playerId,
          order: workOrder,
          applied: false,
          destinationProvinceId: destination,
          ignoreReason: 'destination_tile_unavailable',
        );
        continue;
      }

      final destinationRegion = ProvinceId.regionIdFrom(destination);
      final sourceRegion = ProvinceId.regionIdFrom(unit.locationProvinceId);
      final movedUnit = unit.copyWith(
        locationProvinceId: destination,
        tileKey: destinationTile,
      );
      var ws = state.worldState;
      if (sourceRegion == destinationRegion) {
        ws = ws.updateRegionById(sourceRegion, (region) {
          final next = <Unit>[
            for (final u in region.units)
              if (u.id != unit.id) u,
          ]..add(movedUnit);
          return RegionData(provinces: region.provinces, units: next);
        });
      } else {
        ws = ws.updateRegionById(sourceRegion, (region) {
          final next = <Unit>[
            for (final u in region.units)
              if (u.id != unit.id) u,
          ];
          return RegionData(provinces: region.provinces, units: next);
        });
        ws = ws.updateRegionById(destinationRegion, (region) {
          return RegionData(
            provinces: region.provinces,
            units: [...region.units, movedUnit],
          );
        });
      }
      state = state.withWorldState(ws);
      unitById[unit.id] = movedUnit;
      view = _playerViewWithMovedUnit(view, movedUnit);
      viewByPlayerId[playerId] = view;
      onBundledWorkMoveTrace?.call(
        playerId: playerId,
        order: workOrder,
        applied: true,
        destinationProvinceId: destination,
        destinationTileKey: destinationTile,
      );
    }
  }
  return state;
}

PlayerView _playerViewWithMovedUnit(PlayerView view, Unit movedUnit) {
  return PlayerView(
    playerId: view.playerId,
    player: view.player,
    ownUnitsById: <String, Unit>{...view.ownUnitsById, movedUnit.id: movedUnit},
    provincesById: view.provincesById,
    visibilityByTile: view.visibilityByTile,
    prospectedTiles: view.prospectedTiles,
    diplomacyByOtherId: view.diplomacyByOtherId,
  );
}
