import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart';

/// Civilian-marker draft projection for the human player.
///
/// Extracted from `GameMapAreaStateLogic` (#2575 work item 11) so the
/// civilian projection pipeline lives in a single, separately testable
/// module. `GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft`
/// remains as a thin forwarder for backward compatibility with call sites
/// and existing tests.
class GameMapAreaCivilianDraftProjection {
  GameMapAreaCivilianDraftProjection._();

  /// Projects player-owned civilian markers using current-turn pending orders.
  /// This keeps map feedback in sync with assign flows before turn resolution.
  ///
  /// [civilianMarkerOwnerIds] is the explicit set of owner ids whose civilian
  /// units should be projected onto the region map. When null (legacy), only
  /// [humanPlayerId]'s civilians are projected (single-player behavior). In
  /// observe mode (per SPEC/ui/observe-mode.md), pass the full owner set
  /// resolved from `ShellPlayerContext` so handoff (`isHuman = false` on every
  /// player) does not empty the projection.
  static RegionMapViewData project({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
    Set<String>? civilianMarkerOwnerIds,
  }) {
    final ownerIds = civilianMarkerOwnerIds ?? <String>{humanPlayerId};
    final pendingByUnitId = <String, String>{};
    for (final ownerId in ownerIds) {
      final pending = orders.workOrdersByPlayerId[ownerId] ?? const [];
      for (final order in pending) {
        final target = order.targetTileKey;
        if (target.isEmpty) continue;
        pendingByUnitId[order.unitId] = target;
      }
    }

    final civilianUnitIdsToProject = <String>{
      ...pendingByUnitId.keys,
      for (final marker in region.civilianTileMarkers)
        for (final unitId in marker.unitIds) unitId,
    };
    if (civilianUnitIdsToProject.isEmpty) {
      for (final u in game.worldState.oldWorld.units) {
        if (!ownerIds.contains(u.ownerId) || !_isCivilianUnitType(u.type)) {
          continue;
        }
        if (u.tileKey == null || u.tileKey!.isEmpty) continue;
        civilianUnitIdsToProject.add(u.id);
      }
      for (final u in game.worldState.newWorld.units) {
        if (!ownerIds.contains(u.ownerId) || !_isCivilianUnitType(u.type)) {
          continue;
        }
        if (u.tileKey == null || u.tileKey!.isEmpty) continue;
        civilianUnitIdsToProject.add(u.id);
      }
    }
    if (civilianUnitIdsToProject.isEmpty) {
      return region;
    }

    final unitsById = <String, ct_models.Unit>{
      for (final u in game.worldState.oldWorld.units)
        if (ownerIds.contains(u.ownerId) && _isCivilianUnitType(u.type))
          u.id: u,
      for (final u in game.worldState.newWorld.units)
        if (ownerIds.contains(u.ownerId) && _isCivilianUnitType(u.type))
          u.id: u,
    };
    if (unitsById.isEmpty) {
      return region;
    }
    final visibilityByTile = ownerIds.length == 1
        ? game.worldState.playerVisibilityByTile[ownerIds.single] ??
            const <String, String>{}
        : const <String, String>{};

    final projectedByTile = <String, List<_ProjectedCivilianUnit>>{};
    for (final unitId in civilianUnitIdsToProject) {
      final unit = unitsById[unitId];
      if (unit == null) continue;
      final projectedTile =
          projectedCivilianTileKey(
            unit: unit,
            playerId: unit.ownerId,
            orders: orders,
          ) ??
          unit.tileKey;
      if (projectedTile == null || projectedTile.isEmpty) continue;
      final parsed = tryParseTileKey(projectedTile);
      if (parsed == null || parsed.regionId != region.regionId) continue;
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
    if (projectedByTile.isEmpty) {
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
        civilianTileMarkers: const [],
        fleetTileMarkers: region.fleetTileMarkers,
        warpMarkers: region.warpMarkers,
        townMarkers: region.townMarkers,
        provinceUnitPresenceByProvinceId:
            region.provinceUnitPresenceByProvinceId,
        provincePoliticalOwnerByPrefixedProvinceId:
            region.provincePoliticalOwnerByPrefixedProvinceId,
        seaZoneDisplayNameByPrefixedId: region.seaZoneDisplayNameByPrefixedId,
      );
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
      final parsed = tryParseTileKey(tileKey);
      if (parsed == null) continue;
      final x = parsed.x;
      final y = parsed.y;
      final representative = units.first;
      final representativeIsAssigned =
          representative.pendingTargetTileKey == tileKey ||
          (representative.assignedTileKey == tileKey &&
              representative.status == ct_models.UnitStatus.working);
      final applyCivilianRevealHalo = units.any((u) {
        final isAssignedToTile =
            u.pendingTargetTileKey == tileKey ||
            (u.assignedTileKey == tileKey &&
                u.status == ct_models.UnitStatus.working);
        if (!isAssignedToTile) return false;
        return visibilityByTile[tileKey] == VisibilityLevel.fogged.name;
      });
      projectedMarkers.add(
        CivilianTileMarkerView(
          tileKey: tileKey,
          x: x,
          y: y,
          localProvinceId: parsed.provinceLocalId,
          unitIds: units.map((u) => u.unitId).toList(),
          unitTypes: {for (final u in units) u.unitId: u.unitType},
          representativeUnitType: representative.unitType,
          stackCount: units.length,
          representativeIsAssigned: representativeIsAssigned,
          applyCivilianRevealHalo: applyCivilianRevealHalo,
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
      fleetTileMarkers: region.fleetTileMarkers,
      warpMarkers: region.warpMarkers,
      townMarkers: region.townMarkers,
      provinceUnitPresenceByProvinceId: region.provinceUnitPresenceByProvinceId,
      provincePoliticalOwnerByPrefixedProvinceId:
          region.provincePoliticalOwnerByPrefixedProvinceId,
      seaZoneDisplayNameByPrefixedId: region.seaZoneDisplayNameByPrefixedId,
    );
  }
}

bool _isCivilianUnitType(String unitType) {
  final role = unitRoleForType(unitType);
  if (role == null) return false;
  return role != UnitRole.military && role != UnitRole.naval;
}

String _normalizeCivilianTypeForPriority(String type) {
  return type.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
}

int _civilianIconPriorityForType(String type) {
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
