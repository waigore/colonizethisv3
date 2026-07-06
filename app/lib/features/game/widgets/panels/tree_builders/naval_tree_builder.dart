// Pure data for Naval Units panel tree. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        GamePlayerLookup,
        homeFleetIdFor,
        kRegionNewWorld,
        kRegionOldWorld,
        regionIdForSeaZone,
        WorldStateProvinceLookup;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../../l10n/l10n.dart';
import '../../../utils/map_location_resolver.dart';
import '../../../utils/region_labels.dart';
import '../../../utils/sea_zone_name_resolver.dart';
import 'fleet_mission_label.dart';

part 'naval_tree_builder_support_scope.dart';
part 'naval_tree_builder_support_rows.dart';
part 'naval_tree_builder_support_group.dart';

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
      return 'Moving to: $name (dock)';
    }
    final z = o.destinationSeaZoneId!;
    final zReg = regionIdForSeaZone(topology, z) ?? fleetRegionId;
    final zoneKey = prefixedIdHasDelimiter(z) ? z : '$zReg|$z';
    final label = seaZoneDisplayName(
      game: game,
      regionId: zReg,
      seaZoneId: zoneKey,
    );
    return 'Moving to: $label';
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

List<
  ({
    String regionId,
    FleetRow? homeFleet,
    List<NavalTreeLocationNode> locations,
  })
>
buildNavalTree(
  Game game,
  String humanPlayerId,
  MapTopology topology,
  Orders draftOrders,
  AppLocalizations l10n, {
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  String? locationScopeKeyFilter,
}) {
  final player = game.playerById(humanPlayerId) ?? game.players.first;
  final capParts = _capitalTileRegionParts(player.capitalTile);
  final capitalRegionId = capParts.regionId;
  final capitalProvinceLocalId = capParts.localId;

  final result =
      <
        ({
          String regionId,
          FleetRow? homeFleet,
          List<NavalTreeLocationNode> locations,
        })
      >[];

  final provinceByRegionAndId = <String, Map<String, Province>>{
    kRegionOldWorld: {
      for (final p in game.worldState.oldWorld.provinces)
        '${p.regionId}|${p.id}': p,
      for (final p in game.worldState.oldWorld.provinces) p.id: p,
    },
    kRegionNewWorld: {
      for (final p in game.worldState.newWorld.provinces)
        '${p.regionId}|${p.id}': p,
      for (final p in game.worldState.newWorld.provinces) p.id: p,
    },
  };

  final draftMoveByFleetId = <String, NavalMoveOrder>{
    for (final order
        in draftOrders.navalMoveOrdersByPlayerId[humanPlayerId] ?? const [])
      order.fleetId: order,
  };

  game.worldState.forEachRegion((regionId, _) {
    final group = _navalTreeGroupForRegion(
      game: game,
      humanPlayerId: humanPlayerId,
      topology: topology,
      draftOrders: draftOrders,
      l10n: l10n,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
      locationScopeKeyFilter: locationScopeKeyFilter,
      regionId: regionId,
      capitalRegionId: capitalRegionId,
      capitalProvinceLocalId: capitalProvinceLocalId,
      provinceByRegionAndId: provinceByRegionAndId,
      draftMoveByFleetId: draftMoveByFleetId,
    );
    if (group != null) {
      result.add(group);
    }
  });

  return result;
}
