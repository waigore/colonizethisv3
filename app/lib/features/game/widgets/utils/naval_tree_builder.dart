// Pure data for Naval Units panel tree. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show homeFleetIdFor, regionIdForSeaZone;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../units/shared/units_panel_region_label.dart';
import '../../utils/map_location_resolver.dart';
import '../../utils/sea_zone_name_resolver.dart';
import 'fleet_mission_label.dart';

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
    final zoneKey = z.contains('|') ? z : '$zReg|$z';
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
) {
  final player = game.players.firstWhere(
    (p) => p.id == humanPlayerId,
    orElse: () => game.players.first,
  );
  final capitalTile = player.capitalTile;
  String? capitalRegionId;
  String? capitalProvinceLocalId;
  if (capitalTile != null) {
    final tileKey = capitalTile.toTileKey();
    final parts = tileKey.split('|');
    if (parts.length >= 2) {
      capitalRegionId = parts[0];
      capitalProvinceLocalId = parts[1];
    }
  }

  final result =
      <
        ({
          String regionId,
          FleetRow? homeFleet,
          List<NavalTreeLocationNode> locations,
        })
      >[];

  final provinceByRegionAndId = <String, Map<String, Province>>{
    'oldWorld': {
      for (final p in game.worldState.oldWorld.provinces)
        '${p.regionId}|${p.id}': p,
      for (final p in game.worldState.oldWorld.provinces) p.id: p,
    },
    'newWorld': {
      for (final p in game.worldState.newWorld.provinces)
        '${p.regionId}|${p.id}': p,
      for (final p in game.worldState.newWorld.provinces) p.id: p,
    },
  };

  bool isMerchantShip(String typeId) {
    final stats = NavalStatsCatalog.get(typeId);
    return stats.cargoHold > 0;
  }

  for (final regionEntry in {
    'oldWorld': game.worldState.oldWorld,
    'newWorld': game.worldState.newWorld,
  }.entries) {
    final regionId = regionEntry.key;

    final fleetsInRegion = game.worldState.fleets
        .where(
          (f) =>
              f.ownerId == humanPlayerId &&
              f.regionId == regionId &&
              f.shipTypeIds.isNotEmpty,
        )
        .toList();
    if (fleetsInRegion.isEmpty && capitalRegionId != regionId) {
      continue;
    }

    FleetRow? homeFleetRow;
    final ports = <String, List<FleetRow>>{};
    final seas = <String, List<FleetRow>>{};

    for (final fleet in fleetsInRegion) {
      final isAtSea = fleet.isAtSea && fleet.seaZoneId != null;
      final inPortId = fleet.inPortAtProvinceId;

      final shipCounts = <String, int>{};
      int totalShips = 0;
      int warships = 0;
      int merchants = 0;
      int cargoCapacity = 0;
      double strength = 0;
      for (final typeId in fleet.shipTypeIds) {
        shipCounts[typeId] = (shipCounts[typeId] ?? 0) + 1;
        totalShips += 1;
        final stats = NavalStatsCatalog.get(typeId);
        cargoCapacity += stats.cargoHold;
        strength += NavalStatsCatalog.shipStrength(typeId);
        if (isMerchantShip(typeId)) {
          merchants += 1;
        } else {
          warships += 1;
        }
      }

      final atPlayerCapitalPort =
          capitalRegionId != null &&
          capitalProvinceLocalId != null &&
          !isAtSea &&
          regionId == capitalRegionId &&
          inPortId != null &&
          (inPortId == capitalProvinceLocalId ||
              inPortId == '$capitalRegionId|$capitalProvinceLocalId');
      final isHomeFleet =
          fleet.id == homeFleetIdFor(humanPlayerId) && atPlayerCapitalPort;

      String locationLabel;
      String? tileKey;
      String locationKey;
      if (isAtSea) {
        final seaZoneId = fleet.seaZoneId!;
        final zoneKey = seaZoneId.contains('|')
            ? seaZoneId
            : '$regionId|$seaZoneId';
        final zoneLabel = seaZoneDisplayName(
          game: game,
          regionId: regionId,
          seaZoneId: zoneKey,
        );
        locationLabel = '${unitsPanelRegionLabel(regionId)} — $zoneLabel';
        tileKey = tileKeyForSeaZoneLocation(game, regionId, zoneKey);
        locationKey = 'sea:$zoneKey';
        final row = FleetRow(
          fleetId: fleet.id,
          label: 'Fleet ${fleet.id}',
          locationLabel: locationLabel,
          regionId: regionId,
          missionLabel: fleetMissionDisplayLabel(fleet.mission),
          totalShips: totalShips,
          warshipCount: warships,
          merchantCount: merchants,
          strength: strength,
          tileKey: tileKey,
          isHomeFleet: isHomeFleet,
          shipCountsByType: shipCounts,
          cargoCapacity: cargoCapacity,
          isAtSea: true,
          locationKey: locationKey,
          seaZoneId: zoneKey,
          draftNavalMoveLine: navalDraftMoveLineForFleet(
            game: game,
            topology: topology,
            humanPlayerId: humanPlayerId,
            fleetRegionId: regionId,
            fleetId: fleet.id,
            draftOrders: draftOrders,
          ),
        );
        seas.putIfAbsent(zoneKey, () => []).add(row);
      } else if (inPortId != null) {
        final provinceMap = provinceByRegionAndId[regionId] ?? const {};
        final province =
            provinceMap['$regionId|$inPortId'] ?? provinceMap[inPortId];
        if (province == null) continue;
        tileKey = tileKeyForProvinceLocation(game, province);
        locationLabel =
            '${unitsPanelRegionLabel(regionId)} — ${province.displayName ?? province.id}';
        locationKey = 'port:${province.regionId}|${province.id}';
        final row = FleetRow(
          fleetId: fleet.id,
          label: isHomeFleet ? 'Home Fleet' : 'Fleet ${fleet.id}',
          locationLabel: locationLabel,
          regionId: regionId,
          missionLabel: fleetMissionDisplayLabel(fleet.mission),
          totalShips: totalShips,
          warshipCount: warships,
          merchantCount: merchants,
          strength: strength,
          tileKey: tileKey,
          isHomeFleet: isHomeFleet,
          shipCountsByType: shipCounts,
          cargoCapacity: cargoCapacity,
          isAtSea: false,
          locationKey: locationKey,
          inPortAtProvinceId: inPortId,
          draftNavalMoveLine: isHomeFleet
              ? null
              : navalDraftMoveLineForFleet(
                  game: game,
                  topology: topology,
                  humanPlayerId: humanPlayerId,
                  fleetRegionId: regionId,
                  fleetId: fleet.id,
                  draftOrders: draftOrders,
                ),
        );
        if (isHomeFleet) {
          homeFleetRow = row;
        } else {
          final fullProvinceId = '${province.regionId}|${province.id}';
          ports.putIfAbsent(fullProvinceId, () => []).add(row);
        }
      }
    }

    if (capitalRegionId == regionId &&
        capitalProvinceLocalId != null &&
        homeFleetRow == null) {
      final provinceMap = provinceByRegionAndId[regionId] ?? const {};
      final province =
          provinceMap['$capitalRegionId|$capitalProvinceLocalId'] ??
          provinceMap[capitalProvinceLocalId];
      if (province != null) {
        final tileKey = tileKeyForProvinceLocation(game, province);
        final locationLabel =
            '${unitsPanelRegionLabel(regionId)} — ${province.displayName ?? province.id}';
        homeFleetRow = FleetRow(
          fleetId: homeFleetIdFor(humanPlayerId),
          label: 'Home Fleet',
          locationLabel: locationLabel,
          regionId: regionId,
          missionLabel: fleetMissionDisplayLabel(FleetMission.none),
          totalShips: 0,
          warshipCount: 0,
          merchantCount: 0,
          strength: 0,
          tileKey: tileKey,
          isHomeFleet: true,
          shipCountsByType: const {},
          cargoCapacity: 0,
          isAtSea: false,
          locationKey: 'port:${province.regionId}|${province.id}',
          inPortAtProvinceId: '$capitalRegionId|$capitalProvinceLocalId',
          draftNavalMoveLine: null,
        );
      }
    }

    final locations = <NavalTreeLocationNode>[];

    final provinceIds = ports.keys.toList()..sort();
    for (final fullProvinceId in provinceIds) {
      final provinceMap = provinceByRegionAndId[regionId] ?? const {};
      final province = provinceMap[fullProvinceId];
      if (province == null) continue;
      final fleets = ports[fullProvinceId]!
        ..sort((a, b) => a.label.compareTo(b.label));
      locations.add(NavalTreePortNode(province: province, fleets: fleets));
    }

    final seaZoneKeys = seas.keys.toList()..sort();
    for (final zoneKey in seaZoneKeys) {
      final zoneLabel = seaZoneDisplayName(
        game: game,
        regionId: regionId,
        seaZoneId: zoneKey,
      );
      final fleets = seas[zoneKey]!..sort((a, b) => a.label.compareTo(b.label));
      locations.add(
        NavalTreeSeaZoneNode(
          seaZoneLabel: zoneLabel,
          regionId: regionId,
          fleets: fleets,
        ),
      );
    }

    if (homeFleetRow != null || locations.isNotEmpty) {
      result.add((
        regionId: regionId,
        homeFleet: homeFleetRow,
        locations: locations,
      ));
    }
  }

  return result;
}
