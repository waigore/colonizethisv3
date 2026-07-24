import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show regionIdForSeaZone, WorldStateProvinceLookup;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../province_overlay/sea_zone_name_resolver.dart';
import 'draft_move_destination_line.dart';

String? navalDraftMoveLineForFleet({
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required String fleetRegionId,
  required String fleetId,
  required Orders draftOrders,
}) {
  final moves =
      draftOrders.navalMoveOrdersByPlayerId[humanPlayerId] ?? const [];
  for (final o in moves) {
    if (o.fleetId != fleetId) continue;
    if (o.isDock) {
      final pid = o.destinationPortProvinceId!;
      final p = game.worldState.tryGetProvince(pid);
      final name = p?.displayName ?? p?.id ?? pid;
      return formatDraftMoveDestinationLine(name, parenthetical: 'dock');
    }
    final z = o.destinationSeaZoneId!;
    final zReg = regionIdForSeaZone(topology, z) ?? fleetRegionId;
    final zoneKey = prefixedIdHasDelimiter(z) ? z : '$zReg|$z';
    final label = seaZoneDisplayName(
      game: game,
      regionId: zReg,
      seaZoneId: zoneKey,
    );
    return formatDraftMoveDestinationLine(label);
  }
  return null;
}

class FleetRow {
  FleetRow({
    required this.fleetId,
    required this.label,
    required this.locationLabel,
    required this.regionId,
    required this.missionLabel,
    required this.totalShips,
    required this.warshipCount,
    required this.merchantCount,
    required this.strength,
    required this.tileKey,
    required this.isHomeFleet,
    required this.shipCountsByType,
    required this.cargoCapacity,
    required this.isAtSea,
    required this.locationKey,
    this.inPortAtProvinceId,
    this.seaZoneId,
    this.draftNavalMoveLine,
  });

  final String fleetId;
  final String label;
  final String locationLabel;
  final String regionId;
  final String missionLabel;
  final int totalShips;
  final int warshipCount;
  final int merchantCount;
  final double strength;
  final String? tileKey;
  final bool isHomeFleet;
  final Map<String, int> shipCountsByType;
  final int cargoCapacity;
  final bool isAtSea;
  final String locationKey;
  final String? inPortAtProvinceId;
  final String? seaZoneId;
  final String? draftNavalMoveLine;
}

abstract class NavalTreeLocationNode {
  String get displayLabel;
  String get regionId;
  List<FleetRow> get fleets;
}

class NavalTreePortNode extends NavalTreeLocationNode {
  NavalTreePortNode({required this.province, required this.fleets});

  final Province province;

  @override
  final List<FleetRow> fleets;

  @override
  String get displayLabel => province.displayName ?? province.id;

  @override
  String get regionId => province.regionId;
}

class NavalTreeSeaZoneNode extends NavalTreeLocationNode {
  NavalTreeSeaZoneNode({
    required this.seaZoneLabel,
    required this.regionId,
    required this.fleets,
  });

  final String seaZoneLabel;

  @override
  final String regionId;

  @override
  final List<FleetRow> fleets;

  @override
  String get displayLabel => seaZoneLabel;
}

List<FleetRow> flattenNavalTree(
  List<
    ({
      String regionId,
      FleetRow? homeFleet,
      List<NavalTreeLocationNode> locations,
    })
  >
  tree,
) {
  final rows = <FleetRow>[];
  for (final group in tree) {
    if (group.homeFleet != null) {
      rows.add(group.homeFleet!);
    }
    for (final loc in group.locations) {
      rows.addAll(loc.fleets);
    }
  }
  return rows;
}
