// Naval units panel. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../widgets/ct_panel.dart';

String _regionLabel(String regionId) {
  switch (regionId) {
    case 'oldWorld':
      return 'Old World';
    case 'newWorld':
      return 'New World';
    default:
      return regionId;
  }
}

String _missionLabel(FleetMission m) {
  switch (m) {
    case FleetMission.none:
      return 'None';
    case FleetMission.patrol:
      return 'Patrol';
    case FleetMission.blockade:
      return 'Blockade';
    case FleetMission.beachhead:
      return 'Beachhead';
    case FleetMission.defend:
      return 'Defend';
  }
}

String? tileKeyForProvinceLocation(Game game, Province province) {
  final prefixedId = '${province.regionId}|${province.id}';
  if (province.townTileKey != null && province.townTileKey!.isNotEmpty) {
    return province.townTileKey;
  }
  final byProvince =
      game.worldState.tileKeysByRegionAndProvince[province.regionId];
  final tiles = byProvince?[prefixedId] ?? byProvince?[province.id];
  if (tiles != null && tiles.isNotEmpty) return tiles.first;
  return null;
}

String? tileKeyForSeaZoneLocation(
  Game game,
  String regionId,
  String seaZoneId,
) {
  final localSeaZone =
      seaZoneId.contains('|') ? seaZoneId.split('|').last : seaZoneId;
  for (final e in game.worldState.portsByProvinceSeaboard.entries) {
    final parts = e.key.split('|');
    if (parts.length < 2) continue;
    final keyRegion = parts[0];
    final keySeaZone = parts.last;
    if (keyRegion == regionId && keySeaZone == localSeaZone) {
      return e.value;
    }
  }
  return null;
}

class _FleetRow {
  _FleetRow({
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
}

abstract class _FleetLocationNode {
  String get displayLabel;

  String get regionId;

  List<_FleetRow> get fleets;
}

class _PortLocationNode extends _FleetLocationNode {
  _PortLocationNode({
    required this.province,
    required this.fleets,
  });

  final Province province;

  @override
  final List<_FleetRow> fleets;

  @override
  String get displayLabel => province.displayName ?? province.id;

  @override
  String get regionId => province.regionId;
}

class _SeaZoneLocationNode extends _FleetLocationNode {
  _SeaZoneLocationNode({
    required this.seaZoneLabel,
    required this.regionId,
    required this.fleets,
  });

  final String seaZoneLabel;

  @override
  final String regionId;

  @override
  final List<_FleetRow> fleets;

  @override
  String get displayLabel => seaZoneLabel;
}

List<({
  String regionId,
  _FleetRow? homeFleet,
  List<_FleetLocationNode> locations,
})> _buildNavalTree(
  Game game,
  String humanPlayerId,
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

  final result = <({
    String regionId,
    _FleetRow? homeFleet,
    List<_FleetLocationNode> locations,
  })>[];

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

  bool _isMerchant(String typeId) {
    final stats = NavalStatsCatalog.get(typeId);
    return stats.cargoHold > 0;
  }

  double _shipStrength(String typeId) {
    final stats = NavalStatsCatalog.get(typeId);
    // Mirrors SPEC/game/ships-and-naval.md § Naval Strength Aggregation Formula:
    // FRP weight 1.0; RNG weight 0.4; ARM contributes via durability; MV weight 0.1.
    final durability = stats.hull * (1 + stats.armour / 10.0);
    return stats.firepower * 1.0 +
        stats.range * 0.4 +
        stats.movement * 0.1 +
        durability;
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

    _FleetRow? homeFleetRow;
    final ports = <String, List<_FleetRow>>{};
    final seas = <String, List<_FleetRow>>{};

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
        strength += _shipStrength(typeId);
        if (_isMerchant(typeId)) {
          merchants += 1;
        } else {
          warships += 1;
        }
      }

      final isHomeFleet = capitalRegionId != null &&
          capitalProvinceLocalId != null &&
          !isAtSea &&
          regionId == capitalRegionId &&
          inPortId != null &&
          (inPortId == capitalProvinceLocalId ||
              inPortId == '$capitalRegionId|$capitalProvinceLocalId');

      String locationLabel;
      String? tileKey;
      if (isAtSea) {
        final seaZoneId = fleet.seaZoneId!;
        final zoneKey =
            seaZoneId.contains('|') ? seaZoneId : '$regionId|$seaZoneId';
        final zoneLabel =
            zoneKey.contains('|') ? zoneKey.split('|').last : zoneKey;
        locationLabel = '${_regionLabel(regionId)} — $zoneLabel';
        tileKey = tileKeyForSeaZoneLocation(game, regionId, zoneKey);
        final row = _FleetRow(
          fleetId: fleet.id,
          label: 'Fleet ${fleet.id}',
          locationLabel: locationLabel,
          regionId: regionId,
          missionLabel: _missionLabel(fleet.mission),
          totalShips: totalShips,
          warshipCount: warships,
          merchantCount: merchants,
          strength: strength,
          tileKey: tileKey,
          isHomeFleet: isHomeFleet,
          shipCountsByType: shipCounts,
          cargoCapacity: cargoCapacity,
        );
        seas.putIfAbsent(zoneKey, () => []).add(row);
      } else if (inPortId != null) {
        final provinceMap = provinceByRegionAndId[regionId] ?? const {};
        final province =
            provinceMap['$regionId|$inPortId'] ?? provinceMap[inPortId];
        if (province == null) continue;
        tileKey = tileKeyForProvinceLocation(game, province);
        locationLabel =
            '${_regionLabel(regionId)} — ${province.displayName ?? province.id}';
        final row = _FleetRow(
          fleetId: fleet.id,
          label: isHomeFleet ? 'Home Fleet' : 'Fleet ${fleet.id}',
          locationLabel: locationLabel,
          regionId: regionId,
          missionLabel: _missionLabel(fleet.mission),
          totalShips: totalShips,
          warshipCount: warships,
          merchantCount: merchants,
          strength: strength,
          tileKey: tileKey,
          isHomeFleet: isHomeFleet,
          shipCountsByType: shipCounts,
          cargoCapacity: cargoCapacity,
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
      final province = provinceMap['$capitalRegionId|$capitalProvinceLocalId'] ??
          provinceMap[capitalProvinceLocalId];
      if (province != null) {
        final tileKey = tileKeyForProvinceLocation(game, province);
        final locationLabel =
            '${_regionLabel(regionId)} — ${province.displayName ?? province.id}';
        homeFleetRow = _FleetRow(
          fleetId: 'home_fleet',
          label: 'Home Fleet',
          locationLabel: locationLabel,
          regionId: regionId,
          missionLabel: _missionLabel(FleetMission.none),
          totalShips: 0,
          warshipCount: 0,
          merchantCount: 0,
          strength: 0,
          tileKey: tileKey,
          isHomeFleet: true,
          shipCountsByType: const {},
          cargoCapacity: 0,
        );
      }
    }

    final locations = <_FleetLocationNode>[];

    final provinceIds = ports.keys.toList()..sort();
    for (final fullProvinceId in provinceIds) {
      final provinceMap = provinceByRegionAndId[regionId] ?? const {};
      final province = provinceMap[fullProvinceId];
      if (province == null) continue;
      final fleets = ports[fullProvinceId]!..sort(
          (a, b) => a.label.compareTo(b.label),
        );
      locations.add(
        _PortLocationNode(
          province: province,
          fleets: fleets,
        ),
      );
    }

    final seaZoneKeys = seas.keys.toList()..sort();
    for (final zoneKey in seaZoneKeys) {
      final zoneLabel =
          zoneKey.contains('|') ? zoneKey.split('|').last : zoneKey;
      final fleets = seas[zoneKey]!..sort(
          (a, b) => a.label.compareTo(b.label),
        );
      locations.add(
        _SeaZoneLocationNode(
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

class NavalUnitsPanel extends StatelessWidget {
  const NavalUnitsPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    this.onLocateFleet,
  });

  final Game game;
  final String humanPlayerId;

  final void Function(String tileKey, String regionId)? onLocateFleet;

  @override
  Widget build(BuildContext context) {
    final tree = _buildNavalTree(game, humanPlayerId);
    final hasAny =
        tree.any((group) => group.homeFleet != null || group.locations.isNotEmpty);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: CtPanel(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Naval Units',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: hasAny
                    ? ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        children: [
                          for (final group in tree) ...[
                            _RegionHeader(
                              label: _regionLabel(group.regionId),
                            ),
                            if (group.homeFleet != null)
                              _FleetExpansionTile(
                                row: group.homeFleet!,
                                onTap: group.homeFleet!.tileKey != null &&
                                        onLocateFleet != null
                                    ? () => onLocateFleet!(
                                          group.homeFleet!.tileKey!,
                                          group.homeFleet!.regionId,
                                        )
                                    : null,
                              ),
                            for (final loc in group.locations) ...[
                              _LocationHeader(
                                label: loc.displayLabel,
                                regionLabel: _regionLabel(loc.regionId),
                              ),
                              for (final row in loc.fleets)
                                _FleetExpansionTile(
                                  row: row,
                                  onTap: row.tileKey != null &&
                                          onLocateFleet != null
                                      ? () => onLocateFleet!(
                                            row.tileKey!,
                                            row.regionId,
                                          )
                                      : null,
                                ),
                            ],
                          ],
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No naval units',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegionHeader extends StatelessWidget {
  const _RegionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _LocationHeader extends StatelessWidget {
  const _LocationHeader({
    required this.label,
    required this.regionLabel,
  });

  final String label;
  final String regionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 6, bottom: 2),
      child: Text(
        '$label — $regionLabel',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ),
    );
  }
}

class _FleetExpansionTile extends StatelessWidget {
  const _FleetExpansionTile({
    required this.row,
    this.onTap,
  });

  final _FleetRow row;
  final VoidCallback? onTap;

  String _summary() {
    final parts = <String>[];
    parts.add('Total ships: ${row.totalShips}');
    parts.add('Strength: ${row.strength.toStringAsFixed(1)}');
    if (row.warshipCount > 0) {
      parts.add('${row.warshipCount} warships');
    }
    if (row.merchantCount > 0) {
      parts.add('${row.merchantCount} merchants');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ExpansionTile(
        title: Text(row.label),
        subtitle: Text(
          '${row.locationLabel}\nMission: ${row.missionLabel} · ${_summary()}',
        ),
        dense: true,
        onExpansionChanged: (_) {
          if (onTap != null) {
            onTap!();
          }
        },
        children: [
          if (row.shipCountsByType.isEmpty)
            const ListTile(
              title: Text('No ships in this fleet'),
              dense: true,
            )
          else ...[
            for (final entry in row.shipCountsByType.entries)
              ListTile(
                title: Text('${entry.key}: ${entry.value}'),
                dense: true,
              ),
          ],
          ListTile(
            title: Text('Strength: ${row.strength.toStringAsFixed(1)}'),
            dense: true,
          ),
          ListTile(
            title: Text(
              row.isHomeFleet
                  ? 'Cargo capacity: ${row.cargoCapacity}'
                  : 'Cargo capacity (if assigned): ${row.cargoCapacity}',
            ),
            dense: true,
          ),
        ],
      ),
    );
  }
}

