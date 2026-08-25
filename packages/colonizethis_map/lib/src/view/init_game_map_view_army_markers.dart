/// Human army stack markers for player-app map taps.
/// SPEC/program/map-visualization.md; SPEC/ui/map-widget.md. Refs #4384.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'init_game_map_view_data.dart';
import 'init_game_map_view_human_player_ids.dart';
import 'init_game_map_view_tile_marker_sort.dart';

/// Builds [ArmyTileMarkerView] stacks for one region's view data.
class InitGameMapViewArmyMarkers {
  const InitGameMapViewArmyMarkers._();

  static List<ArmyTileMarkerView> buildArmyTileMarkersForRegion({
    required Game game,
    required String regionId,
    required List<TownMarkerView> towns,
  }) {
    final humanIds = humanPlayerIds(game);
    if (humanIds.isEmpty) {
      return const [];
    }

    final townByLocalId = <String, TownMarkerView>{
      for (final town in towns) town.provinceId: town,
    };
    final byProvince = <String, List<Army>>{};
    for (final army in game.worldState.armies) {
      if (!_includeArmy(army, regionId, humanIds)) {
        continue;
      }
      byProvince.putIfAbsent(army.stationedProvinceId, () => []).add(army);
    }

    final markers = <ArmyTileMarkerView>[];
    for (final entry in byProvince.entries) {
      final localId = ProvinceId.localIdFrom(entry.key);
      final town = townByLocalId[localId];
      if (town == null) {
        continue;
      }
      final armies = entry.value.toList()..sort((a, b) => a.id.compareTo(b.id));
      final armyIds = [for (final a in armies) a.id];
      final fieldArmyIds = [
        for (final a in armies)
          if (!a.isHomeArmy) a.id,
      ];
      markers.add(
        ArmyTileMarkerView(
          tileKey: '$regionId|$localId|${town.x}|${town.y}',
          x: town.x,
          y: town.y,
          provinceId: entry.key,
          armyIds: armyIds,
          fieldArmyIds: fieldArmyIds,
          stackCount: armyIds.length,
          hasHomeArmy: armies.any((a) => a.isHomeArmy),
        ),
      );
    }
    sortTileAnchoredMarkers(
      markers,
      yOf: (m) => m.y,
      xOf: (m) => m.x,
      tileKeyOf: (m) => m.tileKey,
    );
    return markers;
  }

  static bool _includeArmy(Army army, String regionId, Set<String> humanIds) {
    if (!humanIds.contains(army.ownerId) || army.regionId != regionId) {
      return false;
    }
    if (ProvinceId.regionIdFrom(army.stationedProvinceId) != regionId) {
      return false;
    }
    if (army.isHomeArmy) {
      return true;
    }
    return army.regimentUnitIds.isNotEmpty;
  }
}
