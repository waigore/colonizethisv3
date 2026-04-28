// Pure data for Naval Units panel tree. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show homeFleetIdFor, regionIdForSeaZone, tryGetProvince;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../l10n/app_localizations.dart';
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
      final p = tryGetProvince(game.worldState, pid);
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
  AppLocalizations l10n, {
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  String? locationScopeKeyFilter,
}) {
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

  final draftMoveByFleetId = <String, NavalMoveOrder>{
    for (final order
        in draftOrders.navalMoveOrdersByPlayerId[humanPlayerId] ?? const [])
      order.fleetId: order,
  };

  String resolveSeaZoneRegion({
    required String seaZoneId,
    required String fallbackRegionId,
  }) {
    final byTopology = regionIdForSeaZone(topology, seaZoneId);
    if (byTopology != null) {
      return byTopology;
    }
    final localSeaZoneId = seaZoneId.contains('|')
        ? seaZoneId.split('|').last
        : seaZoneId;
    for (final node in topology.nodes) {
      if (node.type != TopologyNodeType.seaZone) continue;
      final nodeLocal = node.id.contains('|')
          ? node.id.split('|').last
          : node.id;
      if (nodeLocal == localSeaZoneId) {
        return node.regionId;
      }
    }
    return fallbackRegionId;
  }

  String normalizedSeaScope({
    required String seaZoneId,
    required String fallbackRegionId,
  }) {
    final regionId = resolveSeaZoneRegion(
      seaZoneId: seaZoneId,
      fallbackRegionId: fallbackRegionId,
    );
    final local = seaZoneId.contains('|')
        ? seaZoneId.split('|').last
        : seaZoneId;
    return 'sea:$regionId|$local';
  }

  String normalizedPortScope(Province province) {
    final localProvinceId = ProvinceId.isPrefixed(province.id)
        ? ProvinceId.localIdFrom(province.id)
        : province.id;
    return 'port:${province.regionId}|$localProvinceId';
  }

  String? regionIdFromScopeKey(String? scopeKey) {
    if (scopeKey == null || scopeKey.isEmpty) return null;
    final colon = scopeKey.indexOf(':');
    if (colon == -1 || colon >= scopeKey.length - 1) return null;
    final payload = scopeKey.substring(colon + 1);
    if (!payload.contains('|')) return null;
    return payload.split('|').first;
  }

  String? projectedLocationScopeForFleet(Fleet fleet) {
    final move = draftMoveByFleetId[fleet.id];
    if (move != null) {
      if (move.isDock) {
        final pid = move.destinationPortProvinceId!;
        final province = tryGetProvince(game.worldState, pid);
        if (province != null) {
          return normalizedPortScope(province);
        }
        return 'port:$pid';
      }
      return normalizedSeaScope(
        seaZoneId: move.destinationSeaZoneId!,
        fallbackRegionId: fleet.regionId,
      );
    }
    if (fleet.isAtSea && fleet.seaZoneId != null) {
      return normalizedSeaScope(
        seaZoneId: fleet.seaZoneId!,
        fallbackRegionId: fleet.regionId,
      );
    }
    if (fleet.inPortAtProvinceId != null) {
      final province = tryGetProvince(
        game.worldState,
        fleet.inPortAtProvinceId!,
      );
      if (province != null) {
        return normalizedPortScope(province);
      }
      return 'port:${fleet.inPortAtProvinceId!}';
    }
    return null;
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
              (f.shipTypeIds.isNotEmpty ||
                  f.id == homeFleetIdFor(humanPlayerId)),
        )
        .where((fleet) {
          if (locationScopeKeyFilter == null) {
            return fleet.regionId == regionId;
          }
          final projectedScope = projectedLocationScopeForFleet(fleet);
          if (projectedScope != locationScopeKeyFilter) {
            return false;
          }
          final scopeRegionId = regionIdFromScopeKey(projectedScope);
          return scopeRegionId == regionId;
        })
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
      final projectedScope = projectedLocationScopeForFleet(fleet);
      if (locationScopeKeyFilter != null &&
          projectedScope != locationScopeKeyFilter) {
        continue;
      }
      final projectedScopeRegionId = regionIdFromScopeKey(projectedScope);
      final rowRegionId = locationScopeKeyFilter != null
          ? (projectedScopeRegionId ?? regionId)
          : regionId;
      final rowTileMap = tileMapByRegion?[rowRegionId];
      final rowTopology = topologyByRegion?[rowRegionId];

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
          rowRegionId == capitalRegionId &&
          inPortId != null &&
          (inPortId == capitalProvinceLocalId ||
              inPortId == '$capitalRegionId|$capitalProvinceLocalId');
      final isHomeFleet =
          fleet.id == homeFleetIdFor(humanPlayerId) && atPlayerCapitalPort;

      String locationLabel;
      String? tileKey;
      String locationKey;
      if (isAtSea) {
        final seaZoneId =
            locationScopeKeyFilter != null &&
                projectedScope != null &&
                projectedScope.startsWith('sea:')
            ? projectedScope.substring(4)
            : fleet.seaZoneId!;
        final zoneKey = seaZoneId.contains('|')
            ? seaZoneId
            : '$rowRegionId|$seaZoneId';
        locationKey = 'sea:$zoneKey';
        final zoneLabel = seaZoneDisplayName(
          game: game,
          regionId: rowRegionId,
          seaZoneId: zoneKey,
        );
        locationLabel = '${unitsPanelRegionLabel(rowRegionId)} — $zoneLabel';
        tileKey = tileKeyForNavalFleetAtSea(
          game: game,
          regionId: rowRegionId,
          seaZoneId: zoneKey,
          tileMap: rowTileMap,
          regionTopology: rowTopology,
        );
        final row = FleetRow(
          fleetId: fleet.id,
          label: l10n.naval_fleetLabel(fleet.id),
          locationLabel: locationLabel,
          regionId: rowRegionId,
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
            fleetRegionId: rowRegionId,
            fleetId: fleet.id,
            draftOrders: draftOrders,
          ),
        );
        seas.putIfAbsent(zoneKey, () => []).add(row);
      } else if (inPortId != null) {
        final provinceMap = provinceByRegionAndId[rowRegionId] ?? const {};
        final scopePortId =
            locationScopeKeyFilter != null &&
                projectedScope != null &&
                projectedScope.startsWith('port:')
            ? projectedScope.substring(5)
            : null;
        final effectivePortId = scopePortId ?? inPortId;
        final province =
            provinceMap['$rowRegionId|$effectivePortId'] ??
            provinceMap[effectivePortId];
        if (province == null) continue;
        locationKey = normalizedPortScope(province);
        tileKey = tileKeyForProvinceLocation(game, province);
        locationLabel =
            '${unitsPanelRegionLabel(rowRegionId)} — ${province.displayName ?? province.id}';
        final row = FleetRow(
          fleetId: fleet.id,
          label: isHomeFleet
              ? l10n.naval_homeFleetLabel
              : l10n.naval_fleetLabel(fleet.id),
          locationLabel: locationLabel,
          regionId: rowRegionId,
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
          inPortAtProvinceId: effectivePortId,
          draftNavalMoveLine: isHomeFleet
              ? null
              : navalDraftMoveLineForFleet(
                  game: game,
                  topology: topology,
                  humanPlayerId: humanPlayerId,
                  fleetRegionId: rowRegionId,
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
