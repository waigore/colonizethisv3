// Naval move-dialog destination pick models and builder.
// SPEC/ui/move-fleet-dialog.md.
//
// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../flame/map_state/map_location_resolver.dart';
import '../province_overlay/sea_zone_name_resolver.dart';
import '../units/shared/region_labels.dart';

sealed class FleetMovePick {
  const FleetMovePick();

  NavalMoveOrder toOrder(String fleetId);
  String get rowLabel;
  void emitLocate(AppEventBus bus, Game game);
}

final class FleetPickSeaZone extends FleetMovePick {
  const FleetPickSeaZone({
    required this.seaZoneId,
    required this.zoneRegionId,
    required this.rowLabel,
  });

  final String seaZoneId;
  final String zoneRegionId;
  @override
  final String rowLabel;

  @override
  NavalMoveOrder toOrder(String fleetId) =>
      NavalMoveOrder(fleetId: fleetId, destinationSeaZoneId: seaZoneId);

  @override
  void emitLocate(AppEventBus bus, Game game) {
    final key = tileKeyForSeaZoneLocation(game, zoneRegionId, seaZoneId);
    if (key == null) return;
    bus.emit(LocateMapTileEvent(tileKey: key, regionId: zoneRegionId));
  }
}

final class FleetPickPort extends FleetMovePick {
  const FleetPickPort({
    required this.fullProvinceId,
    required this.rowLabel,
    required this.provinceRegionId,
  });

  final String fullProvinceId;
  @override
  final String rowLabel;
  final String provinceRegionId;

  @override
  NavalMoveOrder toOrder(String fleetId) => NavalMoveOrder(
    fleetId: fleetId,
    destinationPortProvinceId: fullProvinceId,
  );

  @override
  void emitLocate(AppEventBus bus, Game game) {
    final province = game.worldState.tryGetProvince(fullProvinceId);
    if (province == null) return;
    final key = tileKeyForProvinceLocation(game, province);
    if (key == null) return;
    bus.emit(LocateMapTileEvent(tileKey: key, regionId: provinceRegionId));
  }
}

String fleetMoveDialogTitleLabel(Fleet fleet) => 'Fleet ${fleet.id}';

String _fullProvinceIdForTopologyProvince(
  String topologyProvinceId,
  String regionId,
) {
  if (ProvinceId.isPrefixed(topologyProvinceId)) return topologyProvinceId;
  return ProvinceId.full(regionId, topologyProvinceId);
}

List<FleetMovePick> buildNavalMovePicks({
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required Fleet fleet,
  required String warpLinkLabel,
  required String Function(String regionLabel) warpLinkLabelForRegion,
}) {
  final outSea = <FleetPickSeaZone>[];
  final outPort = <FleetPickPort>[];

  final topo = navalMoveTopologyPicksForFleet(topology: topology, fleet: fleet);
  if (topo.totalCount == 0) return const [];

  final fleetSeaRegion = fleet.isAtSea && fleet.seaZoneId != null
      ? regionIdForSeaZone(topology, fleet.seaZoneId!) ?? fleet.regionId
      : fleet.regionId;

  for (final z in topo.adjacentSeaZoneIds) {
    final zReg = regionIdForSeaZone(topology, z) ?? fleetSeaRegion;
    final regLabel = regionDisplayLabel(zReg);
    final cross = zReg != fleetSeaRegion;
    final isWarp = isWarpZoneSeaZone(topology, z);
    final zoneLabel = seaZoneDisplayName(
      game: game,
      regionId: zReg,
      seaZoneId: z,
    );
    final label = !isWarp
        ? zoneLabel
        : cross
        ? '$zoneLabel ${warpLinkLabelForRegion(regLabel)}'
        : '$zoneLabel $warpLinkLabel';
    outSea.add(
      FleetPickSeaZone(seaZoneId: z, zoneRegionId: zReg, rowLabel: label),
    );
  }
  outSea.sort((a, b) => a.rowLabel.compareTo(b.rowLabel));

  if (fleet.isAtSea && fleet.seaZoneId != null) {
    final rz = regionIdForSeaZone(topology, fleet.seaZoneId!) ?? fleet.regionId;
    final portRows = <({String fullId, String label})>[];
    for (final lp in topo.adjacentProvinceIdsForDock) {
      final full = _fullProvinceIdForTopologyProvince(lp, rz);
      final province = game.worldState.tryGetProvince(full);
      if (province == null || province.ownerId != humanPlayerId) continue;
      final name = province.displayName ?? province.id;
      final isCap = dockOrderTargetsPlayerCapital(game, humanPlayerId, full);
      final label = isCap ? '$name (capital — joins Home Fleet)' : name;
      portRows.add((fullId: full, label: label));
    }
    portRows.sort((a, b) => a.label.compareTo(b.label));
    for (final r in portRows) {
      outPort.add(
        FleetPickPort(
          fullProvinceId: r.fullId,
          rowLabel: r.label,
          provinceRegionId: rz,
        ),
      );
    }
  }

  return [...outSea, ...outPort];
}
