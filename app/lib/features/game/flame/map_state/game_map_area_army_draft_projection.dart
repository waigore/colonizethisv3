import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../core/utils/prefixed_id.dart';
import 'game_map_area_draft_projection_shared.dart';

/// Army-marker draft projection for the human player. Refs #4384.
class GameMapAreaArmyDraftProjection {
  GameMapAreaArmyDraftProjection._();

  static RegionMapViewData project({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
  }) {
    final moves = orders.armyMoveOrdersByPlayerId[humanPlayerId] ?? const [];
    final moveByArmyId = <String, ct_models.ArmyMoveOrder>{
      for (final m in moves) m.armyId: m,
    };
    bool hasDraft(String armyId) => moveByArmyId.containsKey(armyId);

    final armyIdsToProject = <String>{for (final m in moves) m.armyId};
    for (final marker in region.armyTileMarkers) {
      armyIdsToProject.addAll(marker.armyIds);
    }
    if (armyIdsToProject.isEmpty) {
      return region;
    }

    final townByPrefixed = <String, TownMarkerView>{
      for (final town in region.townMarkers)
        '${region.regionId}|${town.provinceId}': town,
    };

    final groups = <String, _ArmyTileProj>{};
    for (final armyId in armyIdsToProject) {
      ct_models.Army? army;
      for (final a in game.worldState.armies) {
        if (a.id == armyId) {
          army = a;
          break;
        }
      }
      if (army == null) {
        continue;
      }
      final mv = moveByArmyId[armyId];
      final stationed = mv?.destinationProvinceId ?? army.stationedProvinceId;
      if (ct_models.ProvinceId.regionIdFrom(stationed) != region.regionId) {
        continue;
      }
      final town = townByPrefixed[stationed];
      if (town == null) {
        continue;
      }
      final local = ct_models.ProvinceId.localIdFrom(stationed);
      final tileKey = '${region.regionId}|$local|${town.x}|${town.y}';
      final g = groups.putIfAbsent(tileKey, _ArmyTileProj.new);
      g.armies.add(army);
      g.provinceId = stationed;
    }

    final out = <ArmyTileMarkerView>[];
    for (final e in groups.entries) {
      final parsed = tryParseTileKey(e.key);
      if (parsed == null) {
        continue;
      }
      final armies = e.value.armies.toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      final armyIds = [for (final a in armies) a.id];
      final fieldIds = [
        for (final a in armies)
          if (!a.isHomeArmy) a.id,
      ];
      out.add(
        ArmyTileMarkerView(
          tileKey: e.key,
          x: parsed.x,
          y: parsed.y,
          provinceId: e.value.provinceId,
          armyIds: armyIds,
          fieldArmyIds: fieldIds,
          stackCount: armyIds.length,
          hasHomeArmy: armies.any((a) => a.isHomeArmy),
          renderGrayscale: fieldIds.isNotEmpty && fieldIds.every(hasDraft),
        ),
      );
    }
    GameMapAreaDraftProjectionShared.sortArmyTileMarkersByMapPosition(out);
    return GameMapAreaDraftProjectionShared.copyRegionMapViewDataMarkerLayers(
      region: region,
      armyTileMarkers: out,
    );
  }
}

class _ArmyTileProj {
  _ArmyTileProj();

  final List<ct_models.Army> armies = [];
  String provinceId = '';
}
