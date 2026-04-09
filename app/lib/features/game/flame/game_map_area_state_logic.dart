import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart';

/// Pure-ish helpers for `GameMapArea` state translation.
class GameMapAreaStateLogic {
  static const String _regionOldWorld = 'oldWorld';

  static int regionIndexFromWorldRegionId(String regionId) {
    if (regionId == 'newWorld') return 1;
    return 0; // oldWorld (default)
  }

  static bool isWorkTargetTileProvinceBased(String workTarget) {
    return workTarget == 'explore' ||
        workTarget == 'steal_tech' ||
        workTarget == 'counter_spy';
  }

  /// For province-based work targets, translate the tile key to a canonical tile
  /// key within that province (x=0,y=0).
  static String translateWorkTargetTileKey({
    required String tileKey,
    required String workTarget,
  }) {
    if (!isWorkTargetTileProvinceBased(workTarget)) return tileKey;
    final parts = tileKey.split('|');
    if (parts.length < 2) return tileKey;
    return '${parts[0]}|${parts[1]}|0|0';
  }

  static ct_models.Orders addHumanWorkOrder({
    required ct_models.Orders orders,
    required String humanPlayerId,
    required ct_models.WorkOrder workOrder,
  }) {
    final list = <ct_models.WorkOrder>[
      ...(orders.workOrdersByPlayerId[humanPlayerId] ?? const []),
      workOrder,
    ];
    return orders.copyWith(
      workOrdersByPlayerId: {
        ...orders.workOrdersByPlayerId,
        humanPlayerId: list,
      },
    );
  }

  /// Returns the post-assignment civilian selection key.
  /// Keeps selection only when the selected key already points at the assigned
  /// marker tile; otherwise clears stale blink state.
  static String? selectionAfterWorkAssignment({
    required String? currentSelectedCivilianTileKey,
    required String assignedTileKey,
  }) {
    if (currentSelectedCivilianTileKey == assignedTileKey) {
      return currentSelectedCivilianTileKey;
    }
    return null;
  }

  /// Projects player-owned civilian markers using current-turn pending orders.
  /// This keeps map feedback in sync with assign flows before turn resolution.
  static RegionMapViewData projectCivilianMarkersForHumanDraft({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
  }) {
    if (region.civilianTileMarkers.isEmpty) {
      return region;
    }
    final pendingByUnitId = <String, String>{};
    final pending = orders.workOrdersByPlayerId[humanPlayerId] ?? const [];
    for (final order in pending) {
      final target = order.targetTileKey;
      if (target.isEmpty) continue;
      pendingByUnitId[order.unitId] = target;
    }
    if (pendingByUnitId.isEmpty) {
      return region;
    }

    final regionUnits = region.regionId == _regionOldWorld
        ? game.worldState.oldWorld.units
        : game.worldState.newWorld.units;
    final unitsById = <String, ct_models.Unit>{
      for (final u in regionUnits)
        if (u.ownerId == humanPlayerId && _isCivilianUnitType(u.type)) u.id: u,
    };
    if (unitsById.isEmpty) {
      return region;
    }

    final projectedByTile = <String, List<_ProjectedCivilianUnit>>{};
    for (final marker in region.civilianTileMarkers) {
      for (final unitId in marker.unitIds) {
        final unit = unitsById[unitId];
        if (unit == null) continue;
        final projectedTile =
            pendingByUnitId[unitId] ??
            _firstNonEmpty(unit.assignedTileKey, marker.tileKey);
        final parts = projectedTile.split('|');
        if (parts.length < 4 || parts[0] != region.regionId) continue;
        projectedByTile
            .putIfAbsent(projectedTile, () => <_ProjectedCivilianUnit>[])
            .add(
              _ProjectedCivilianUnit(
                unitId: unitId,
                unitType: unit.type,
                pendingTargetTileKey: pendingByUnitId[unitId],
                assignedTileKey: unit.assignedTileKey,
                status: unit.status,
              ),
            );
      }
    }
    if (projectedByTile.isEmpty) {
      return region;
    }

    final projectedMarkers = <CivilianTileMarkerView>[];
    for (final entry in projectedByTile.entries) {
      final tileKey = entry.key;
      final units = entry.value.toList()
        ..sort((a, b) {
          final p = _civilianIconPriorityForType(
            a.unitType,
          ).compareTo(_civilianIconPriorityForType(b.unitType));
          if (p != 0) return p;
          return a.unitId.compareTo(b.unitId);
        });
      final parts = tileKey.split('|');
      final x = int.tryParse(parts[2]);
      final y = int.tryParse(parts[3]);
      if (x == null || y == null) continue;
      final representative = units.first;
      final representativeIsAssigned =
          representative.pendingTargetTileKey == tileKey ||
          (representative.assignedTileKey == tileKey &&
              representative.status == ct_models.UnitStatus.working);
      projectedMarkers.add(
        CivilianTileMarkerView(
          tileKey: tileKey,
          x: x,
          y: y,
          localProvinceId: parts[1],
          unitIds: units.map((u) => u.unitId).toList(),
          unitTypes: {for (final u in units) u.unitId: u.unitType},
          representativeUnitType: representative.unitType,
          stackCount: units.length,
          representativeIsAssigned: representativeIsAssigned,
        ),
      );
    }

    projectedMarkers.sort((a, b) {
      final yc = a.y.compareTo(b.y);
      if (yc != 0) return yc;
      final xc = a.x.compareTo(b.x);
      if (xc != 0) return xc;
      return a.tileKey.compareTo(b.tileKey);
    });

    return RegionMapViewData(
      regionId: region.regionId,
      width: region.width,
      height: region.height,
      cellSize: region.cellSize,
      cells: region.cells,
      capitalMarkers: region.capitalMarkers,
      portMarkers: region.portMarkers,
      factionColors: region.factionColors,
      greatPowerFactionIds: region.greatPowerFactionIds,
      terrainColors: region.terrainColors,
      unitMarkers: region.unitMarkers,
      civilianTileMarkers: projectedMarkers,
      warpMarkers: region.warpMarkers,
      townMarkers: region.townMarkers,
      provinceUnitPresenceByProvinceId: region.provinceUnitPresenceByProvinceId,
      provincePoliticalOwnerByPrefixedProvinceId:
          region.provincePoliticalOwnerByPrefixedProvinceId,
    );
  }

  static String _firstNonEmpty(String? first, String fallback) {
    if (first != null && first.isNotEmpty) {
      return first;
    }
    return fallback;
  }

  static bool _isCivilianUnitType(String unitType) {
    final role = unitRoleForType(unitType);
    if (role == null) return false;
    return role != UnitRole.military && role != UnitRole.naval;
  }

  static String _normalizeCivilianTypeForPriority(String type) {
    return type.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
  }

  static int _civilianIconPriorityForType(String type) {
    final normalized = _normalizeCivilianTypeForPriority(type);
    switch (normalized) {
      case 'builder':
        return 0;
      case 'engineer':
        return 1;
      case 'railbuilder':
        return 2;
      case 'explorer':
        return 3;
      case 'merchant':
        return 4;
      case 'spy':
        return 5;
      default:
        return 999;
    }
  }
}

class _ProjectedCivilianUnit {
  const _ProjectedCivilianUnit({
    required this.unitId,
    required this.unitType,
    required this.pendingTargetTileKey,
    required this.assignedTileKey,
    required this.status,
  });

  final String unitId;
  final String unitType;
  final String? pendingTargetTileKey;
  final String? assignedTileKey;
  final ct_models.UnitStatus status;
}
