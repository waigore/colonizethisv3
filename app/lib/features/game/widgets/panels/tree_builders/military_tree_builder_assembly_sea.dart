import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../flame/map_state/map_location_resolver.dart';
import '../../province_overlay/sea_zone_name_resolver.dart';
import 'fleet_mission_label.dart';
import 'military_tree_builder.dart';

List<MilitarySeaZoneNode> militaryTreeSeaZoneNodesForRegion({
  required Game game,
  required String regionKey,
  required String humanPlayerId,
}) {
  final fleetsInRegion = game.worldState.fleets
      .where(
        (f) =>
            f.ownerId == humanPlayerId &&
            f.regionId == regionKey &&
            f.shipTypeIds.isNotEmpty &&
            f.isAtSea &&
            f.seaZoneId != null,
      )
      .toList();
  final bySeaZone = <String, List<Fleet>>{};
  for (final f in fleetsInRegion) {
    final seaZoneId = f.seaZoneId!;
    final zoneKey = prefixedIdHasDelimiter(seaZoneId)
        ? seaZoneId
        : '$regionKey|$seaZoneId';
    bySeaZone.putIfAbsent(zoneKey, () => []).add(f);
  }

  final seaLocations = <MilitarySeaZoneNode>[];
  final seaZoneKeys = bySeaZone.keys.toList()..sort();
  for (final zoneKey in seaZoneKeys) {
    final fleets = bySeaZone[zoneKey]!;
    final shipTypeIds = <String, int>{};
    FleetMission? mission;
    for (final f in fleets) {
      for (final typeId in f.shipTypeIds) {
        shipTypeIds[typeId] = (shipTypeIds[typeId] ?? 0) + 1;
      }
      mission ??= f.mission;
    }
    final zoneLabel = seaZoneDisplayName(
      game: game,
      regionId: regionKey,
      seaZoneId: zoneKey,
    );
    final tileKey = tileKeyForSeaZoneLocation(game, regionKey, zoneKey);
    final rows = <MilitarySeaShipRow>[];
    for (final typeId in shipTypeIds.keys.toList()..sort()) {
      rows.add(
        MilitarySeaShipRow(
          typeId: typeId,
          count: shipTypeIds[typeId]!,
          statusLabel: fleetMissionDisplayLabel(mission ?? FleetMission.none),
          tileKey: tileKey,
          regionId: regionKey,
        ),
      );
    }
    seaLocations.add(
      MilitarySeaZoneNode(
        seaZoneLabel: zoneLabel,
        regionId: regionKey,
        rows: rows,
      ),
    );
  }
  return seaLocations;
}
