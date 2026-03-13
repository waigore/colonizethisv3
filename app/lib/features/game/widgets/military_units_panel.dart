// Military units panel. SPEC/ui/military-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../widgets/ct_panel.dart';

/// Region id to display label. SPEC/ui/military-units-panel.md.
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

/// Fleet mission to display label.
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

/// Resolves the tile key to use when centering on [province] (town tile or first tile).
/// Returns null if no tile can be resolved. SPEC/ui/military-units-panel.md.
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

/// Resolves a port tile key adjacent to the given sea zone in [regionId].
/// [seaZoneId] may be prefixed (regionId|localId) or local. Returns null if none.
/// SPEC/ui/military-units-panel.md.
String? tileKeyForSeaZoneLocation(
  Game game,
  String regionId,
  String seaZoneId,
) {
  final localSeaZone = seaZoneId.contains('|')
      ? seaZoneId.split('|').last
      : seaZoneId;
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

/// One regiment-type row under a province: type, count, medals, status.
class _RegimentTypeRow {
  _RegimentTypeRow({
    required this.typeId,
    required this.count,
    required this.medalsSummary,
    required this.statusLabel,
    required this.tileKey,
    required this.regionId,
  });

  final String typeId;
  final int count;
  final String medalsSummary;
  final String statusLabel;
  final String? tileKey;
  final String regionId;
}

/// One ship-type row under a sea zone: type, count, status (mission).
class _ShipTypeRow {
  _ShipTypeRow({
    required this.typeId,
    required this.count,
    required this.statusLabel,
    required this.tileKey,
    required this.regionId,
  });

  final String typeId;
  final int count;
  final String statusLabel;
  final String? tileKey;
  final String regionId;
}

/// Location node: either a province (with regiment rows) or a sea zone (with ship rows).
abstract class _LocationNode {
  String get displayLabel;
  String get regionId;
}

class _ProvinceLocationNode extends _LocationNode {
  _ProvinceLocationNode({
    required this.province,
    required this.rows,
  });

  final Province province;
  final List<_RegimentTypeRow> rows;

  @override
  String get displayLabel => province.displayName ?? province.id;

  @override
  String get regionId => province.regionId;
}

class _SeaZoneLocationNode extends _LocationNode {
  _SeaZoneLocationNode({
    required this.seaZoneLabel,
    required this.regionId,
    required this.rows,
  });

  final String seaZoneLabel;
  @override
  final String regionId;
  final List<_ShipTypeRow> rows;

  @override
  String get displayLabel => seaZoneLabel;
}

/// Builds the military tree: per region, list of location nodes (provinces + sea zones) with type rows.
List<({String regionId, List<_LocationNode> locations})> _buildMilitaryTree(
  Game game,
  String humanPlayerId,
) {
  final provinceNames = <String, String>{};
  for (final p in game.worldState.oldWorld.provinces) {
    provinceNames['${p.regionId}|${p.id}'] = p.displayName ?? p.id;
  }
  for (final p in game.worldState.newWorld.provinces) {
    provinceNames['${p.regionId}|${p.id}'] = p.displayName ?? p.id;
  }

  final result = <({String regionId, List<_LocationNode> locations})>[];

  for (final regionEntry in {
    'oldWorld': game.worldState.oldWorld,
    'newWorld': game.worldState.newWorld,
  }.entries) {
    final regionId = regionEntry.key;
    final regionData = regionEntry.value;

    // Regiments in this region: group by full province id, then by type.
    final militaryUnits = regionData.units
        .where((u) =>
            u.ownerId == humanPlayerId && isMilitaryUnit(u.type))
        .toList();
    final byProvince = <String, List<Unit>>{};
    for (final u in militaryUnits) {
      final fullProvinceId = u.provinceId.contains('|')
          ? u.provinceId
          : '$regionId|${u.provinceId}';
      byProvince.putIfAbsent(fullProvinceId, () => []).add(u);
    }

    // Fleets in this region owned by player that are at sea (have seaZoneId).
    final fleetsInRegion = game.worldState.fleets
        .where((f) =>
            f.ownerId == humanPlayerId &&
            f.regionId == regionId &&
            f.shipTypeIds.isNotEmpty &&
            f.isAtSea &&
            f.seaZoneId != null)
        .toList();
    final bySeaZone = <String, List<Fleet>>{};
    for (final f in fleetsInRegion) {
      final seaZoneId = f.seaZoneId!;
      final zoneKey =
          seaZoneId.contains('|') ? seaZoneId : '$regionId|$seaZoneId';
      bySeaZone.putIfAbsent(zoneKey, () => []).add(f);
    }

    final provinceById = {
      for (final p in regionData.provinces) '${p.regionId}|${p.id}': p,
      for (final p in regionData.provinces) p.id: p,
    };

    final locations = <_LocationNode>[];

    // Province nodes with regiment type rows
    final provinceIds = byProvince.keys.toList()..sort();
    for (final fullProvinceId in provinceIds) {
      final units = byProvince[fullProvinceId]!;
      final province = provinceById[fullProvinceId];
      if (province == null) continue;
      final tileKey = tileKeyForProvinceLocation(game, province);

      final byType = <String, List<Unit>>{};
      for (final u in units) {
        byType.putIfAbsent(u.type, () => []).add(u);
      }
      final typeIds = byType.keys.toList()..sort();
      final rows = <_RegimentTypeRow>[];
      for (final typeId in typeIds) {
        final list = byType[typeId]!;
        final medals = list.map((u) => u.medals).toSet();
        final medalsSummary = medals.length == 1
            ? '${medals.single}'
            : '${medals.reduce((a, b) => a < b ? a : b)}–${medals.reduce((a, b) => a > b ? a : b)}';
        final status = list.any((u) => u.status == UnitStatus.working)
            ? UnitStatus.working
            : list.any((u) => u.status == UnitStatus.done)
                ? UnitStatus.done
                : UnitStatus.idle;
        final statusLabel = switch (status) {
          UnitStatus.idle => 'Idle',
          UnitStatus.working => 'Working',
          UnitStatus.done => 'Done',
        };
        rows.add(_RegimentTypeRow(
          typeId: typeId,
          count: list.length,
          medalsSummary: medalsSummary,
          statusLabel: statusLabel,
          tileKey: tileKey,
          regionId: regionId,
        ));
      }
      locations.add(_ProvinceLocationNode(province: province, rows: rows));
    }

    // Sea zone nodes with ship type rows
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
      final zoneLabel = zoneKey.contains('|')
          ? zoneKey.split('|').last
          : zoneKey;
      final tileKey = tileKeyForSeaZoneLocation(game, regionId, zoneKey);
      final rows = <_ShipTypeRow>[];
      for (final typeId in shipTypeIds.keys.toList()..sort()) {
        rows.add(_ShipTypeRow(
          typeId: typeId,
          count: shipTypeIds[typeId]!,
          statusLabel: _missionLabel(mission ?? FleetMission.none),
          tileKey: tileKey,
          regionId: regionId,
        ));
      }
      locations.add(_SeaZoneLocationNode(
        seaZoneLabel: zoneLabel,
        regionId: regionId,
        rows: rows,
      ));
    }

    if (locations.isNotEmpty) {
      result.add((regionId: regionId, locations: locations));
    }
  }

  return result;
}

/// Panel that lists all regiments and ships for the human player in a single tree. SPEC/ui/military-units-panel.md.
class MilitaryUnitsPanel extends StatelessWidget {
  const MilitaryUnitsPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    this.onLocateTile,
  });

  final Game game;
  final String humanPlayerId;

  /// Called when the user taps a row. [tileKey] and [regionId] for highlight/center and tab switch.
  final void Function(String tileKey, String regionId)? onLocateTile;

  @override
  Widget build(BuildContext context) {
    final tree = _buildMilitaryTree(game, humanPlayerId);
    final hasAny = tree.isNotEmpty;

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
                      'Military Units',
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
                              label: _regionLabel(group.regionId)),
                          for (final loc in group.locations) ...[
                            _LocationHeader(
                                label: loc.displayLabel,
                                regionLabel: _regionLabel(loc.regionId)),
                            if (loc is _ProvinceLocationNode)
                              for (final row in loc.rows)
                                _RegimentRow(
                                  row: row,
                                  onTap: row.tileKey != null &&
                                          onLocateTile != null
                                      ? () => onLocateTile!(
                                          row.tileKey!, row.regionId)
                                      : null,
                                ),
                            if (loc is _SeaZoneLocationNode)
                              for (final row in loc.rows)
                                _ShipRow(
                                  row: row,
                                  onTap: row.tileKey != null &&
                                          onLocateTile != null
                                      ? () => onLocateTile!(
                                          row.tileKey!, row.regionId)
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
                          'No military units',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
            ),
          ],
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
            fontWeight: FontWeight.w600),
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
            color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}

class _RegimentRow extends StatelessWidget {
  const _RegimentRow({required this.row, this.onTap});

  final _RegimentTypeRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ListTile(
        title: Text('${row.typeId}: ${row.count}'),
        subtitle: Text(
            'Medals: ${row.medalsSummary} · Status: ${row.statusLabel}'),
        dense: true,
        onTap: onTap,
      ),
    );
  }
}

class _ShipRow extends StatelessWidget {
  const _ShipRow({required this.row, this.onTap});

  final _ShipTypeRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ListTile(
        title: Text('${row.typeId}: ${row.count}'),
        subtitle: Text('Status: ${row.statusLabel}'),
        dense: true,
        onTap: onTap,
      ),
    );
  }
}
