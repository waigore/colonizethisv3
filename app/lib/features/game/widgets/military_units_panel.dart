// Military units panel. SPEC/ui/military-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_event_handler_scope.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../utils/map_location_resolver.dart';
import 'units/shared/location_section_header.dart';
import 'units/shared/region_section_header.dart';
import 'units/shared/units_panel_region_label.dart';
import 'units/shared/units_panel_shell.dart';

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
  _ProvinceLocationNode({required this.province, required this.rows});

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
        .where((u) => u.ownerId == humanPlayerId && isMilitaryUnit(u.type))
        .toList();
    final byProvince = <String, List<Unit>>{};
    for (final u in militaryUnits) {
      final loc = u.locationProvinceId;
      final fullProvinceId = loc.contains('|') ? loc : '$regionId|$loc';
      byProvince.putIfAbsent(fullProvinceId, () => []).add(u);
    }

    // Fleets in this region owned by player that are at sea (have seaZoneId).
    final fleetsInRegion = game.worldState.fleets
        .where(
          (f) =>
              f.ownerId == humanPlayerId &&
              f.regionId == regionId &&
              f.shipTypeIds.isNotEmpty &&
              f.isAtSea &&
              f.seaZoneId != null,
        )
        .toList();
    final bySeaZone = <String, List<Fleet>>{};
    for (final f in fleetsInRegion) {
      final seaZoneId = f.seaZoneId!;
      final zoneKey = seaZoneId.contains('|')
          ? seaZoneId
          : '$regionId|$seaZoneId';
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
        rows.add(
          _RegimentTypeRow(
            typeId: typeId,
            count: list.length,
            medalsSummary: medalsSummary,
            statusLabel: statusLabel,
            tileKey: tileKey,
            regionId: regionId,
          ),
        );
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
        rows.add(
          _ShipTypeRow(
            typeId: typeId,
            count: shipTypeIds[typeId]!,
            statusLabel: _missionLabel(mission ?? FleetMission.none),
            tileKey: tileKey,
            regionId: regionId,
          ),
        );
      }
      locations.add(
        _SeaZoneLocationNode(
          seaZoneLabel: zoneLabel,
          regionId: regionId,
          rows: rows,
        ),
      );
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
    required this.bus,
  });

  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;

  @override
  Widget build(BuildContext context) {
    final tree = _buildMilitaryTree(game, humanPlayerId);
    final hasAny = tree.isNotEmpty;

    return UnitsPanelShell(
      title: 'Military Units',
      actions: [
        CtNinePatchButton(
          onPressed: () {
            Navigator.of(context).maybePop();
            bus.emit(OpenDialogEvent(trainMilitaryDialogId));
          },
          child: const Text('Train'),
        ),
      ],
      hasContent: hasAny,
      listChildren: [
        for (final group in tree) ...[
          RegionSectionHeader(label: unitsPanelRegionLabel(group.regionId)),
          for (final loc in group.locations) ...[
            LocationSectionHeader(
              label: loc.displayLabel,
              regionLabel: unitsPanelRegionLabel(loc.regionId),
            ),
            if (loc is _ProvinceLocationNode)
              for (final row in loc.rows)
                _RegimentRow(
                  row: row,
                  onTap: row.tileKey == null
                      ? null
                      : () => bus.emit(
                          LocateMapTileEvent(
                            tileKey: row.tileKey!,
                            regionId: row.regionId,
                            closeCurrentPanel: true,
                          ),
                        ),
                ),
            if (loc is _SeaZoneLocationNode)
              for (final row in loc.rows)
                _ShipRow(
                  row: row,
                  onTap: row.tileKey == null
                      ? null
                      : () => bus.emit(
                          LocateMapTileEvent(
                            tileKey: row.tileKey!,
                            regionId: row.regionId,
                            closeCurrentPanel: true,
                          ),
                        ),
                ),
          ],
        ],
      ],
      emptyMessage: 'No military units',
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
          'Medals: ${row.medalsSummary} · Status: ${row.statusLabel}',
        ),
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
