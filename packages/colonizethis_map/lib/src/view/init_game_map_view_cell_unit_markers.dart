/// Unit and civilian marker aggregation for [init_game_map_view_builder.dart].
/// SPEC/program/map-visualization.md § Map view model for tools.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../civilian_unit_view.dart';
import '../region_data_access.dart';
import '../tile_key_util.dart';
import 'init_game_map_view_data.dart';
import 'init_game_map_view_human_player_ids.dart';
import 'init_game_map_view_tile_marker_sort.dart';

class InitGameMapViewCellUnitMarkers {
  const InitGameMapViewCellUnitMarkers._();

  static ({
    List<UnitMarkerView> unitMarkers,
    List<CivilianTileMarkerView> civilianTileMarkers,
    Map<String, ProvinceUnitPresenceView> provincePresenceById,
  })
  buildUnitAndCivilianMarkerData({
    required Game game,
    required String regionId,
    required List<Province> provinces,
    required List<CellViewData> cells,
    required Map<String, (int x, int y)> provinceToTile,
    Set<String>? civilianMarkerOwnerIds,
  }) {
    final unitMarkers = <UnitMarkerView>[];
    final civilianUnitsByTileKey = <String, List<Unit>>{};
    final playerOwnedCivilianTileMarkers = <CivilianTileMarkerView>[];
    // Default owner set for civilian markers is the `isHuman` players so
    // callers that do not pass an explicit set keep legacy single-player
    // behavior. Observe-mode call sites (see SPEC/ui/observe-mode.md) pass an
    // explicit set because handoff clears `isHuman` on every player.
    final civilianOwnerIds = civilianMarkerOwnerIds ?? humanPlayerIds(game);
    final provincePresenceById = <String, ProvinceUnitPresenceView>{};
    for (final p in provinces) {
      provincePresenceById[p.id] = const ProvinceUnitPresenceView(
        civilianCount: 0,
        regimentCount: 0,
        shipCount: 0,
        intelVisible: false,
      );
    }

    for (final cell in cells) {
      if (cell.isSea || cell.visibility != TileVisibility.visible) {
        continue;
      }
      final fullProvinceId = ProvinceId.full(regionId, cell.regionCellId);
      final current = provincePresenceById[fullProvinceId];
      if (current == null) {
        continue;
      }
      provincePresenceById[fullProvinceId] = current.copyWith(
        intelVisible: true,
      );
    }

    final regionUnits = regionDataForMapRegionId(
      game.worldState,
      regionId,
    ).units;
    for (final u in regionUnits) {
      final isPlayerOwnedCivilian =
          civilianOwnerIds.contains(u.ownerId) && isCivilianUnitType(u.type);
      if (isPlayerOwnedCivilian) {
        _addCivilianUnitToTileKeyBucket(
          unit: u,
          regionId: regionId,
          civilianUnitsByTileKey: civilianUnitsByTileKey,
        );
      }

      final tile = provinceToTile[u.locationProvinceId];
      if (tile != null) {
        unitMarkers.add(
          UnitMarkerView(x: tile.$1, y: tile.$2, ownerFactionId: u.ownerId),
        );
      }

      final current = provincePresenceById[u.locationProvinceId];
      if (current == null) {
        continue;
      }
      final isRegiment = isMilitaryUnit(u.type);
      provincePresenceById[u.locationProvinceId] = current.copyWith(
        civilianCount: current.civilianCount + (isRegiment ? 0 : 1),
        regimentCount: current.regimentCount + (isRegiment ? 1 : 0),
      );
    }

    for (final entry in civilianUnitsByTileKey.entries) {
      final tileKey = entry.key;
      final units = entry.value.toList()
        ..sort((a, b) {
          final priorityCompare = civilianUnitIconPriorityForType(
            a.type,
          ).compareTo(civilianUnitIconPriorityForType(b.type));
          if (priorityCompare != 0) {
            return priorityCompare;
          }
          return a.id.compareTo(b.id);
        });
      final parsed = tryParseMapTileKey(tileKey);
      if (parsed == null) {
        continue;
      }
      final representativeUnit = units.first;
      final representativeIsAssigned =
          representativeUnit.assignedTileKey == tileKey &&
          representativeUnit.status == UnitStatus.working;
      playerOwnedCivilianTileMarkers.add(
        CivilianTileMarkerView(
          tileKey: tileKey,
          x: parsed.x,
          y: parsed.y,
          localProvinceId: parsed.localId,
          unitIds: units.map((unit) => unit.id).toList(),
          unitTypes: {for (final unit in units) unit.id: unit.type},
          representativeUnitType: representativeUnit.type,
          stackCount: units.length,
          representativeIsAssigned: representativeIsAssigned,
        ),
      );
    }
    sortTileAnchoredMarkers(
      playerOwnedCivilianTileMarkers,
      yOf: (m) => m.y,
      xOf: (m) => m.x,
      tileKeyOf: (m) => m.tileKey,
    );

    return (
      unitMarkers: unitMarkers,
      civilianTileMarkers: playerOwnedCivilianTileMarkers,
      provincePresenceById: provincePresenceById,
    );
  }

  static void _addCivilianUnitToTileKeyBucket({
    required Unit unit,
    required String regionId,
    required Map<String, List<Unit>> civilianUnitsByTileKey,
  }) {
    final tileKey = unit.tileKey;
    if (tileKey == null || tileKey.isEmpty) {
      return;
    }
    final parsed = tryParseMapTileKey(tileKey);
    if (parsed == null || parsed.regionId != regionId) {
      return;
    }
    civilianUnitsByTileKey.putIfAbsent(tileKey, () => []).add(unit);
  }
}
