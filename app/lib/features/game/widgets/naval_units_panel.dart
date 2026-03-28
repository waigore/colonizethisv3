// Naval units panel. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../widgets/ct_nine_patch_button.dart';
import 'split_fleet_dialog.dart';
import 'units/shared/location_section_header.dart';
import 'units/shared/region_section_header.dart';
import 'units/shared/units_panel_region_label.dart';
import 'units/shared/units_panel_shell.dart';

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
    required this.isAtSea,
    required this.locationKey,
    this.inPortAtProvinceId,
    this.seaZoneId,
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
}

abstract class _FleetLocationNode {
  String get displayLabel;
  String get regionId;
  List<_FleetRow> get fleets;
}

class _PortLocationNode extends _FleetLocationNode {
  _PortLocationNode({required this.province, required this.fleets});

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

List<_FleetRow> _flattenTree(
  List<
    ({
      String regionId,
      _FleetRow? homeFleet,
      List<_FleetLocationNode> locations,
    })
  >
  tree,
) {
  final rows = <_FleetRow>[];
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
  ({String regionId, _FleetRow? homeFleet, List<_FleetLocationNode> locations})
>
_buildNavalTree(Game game, String humanPlayerId) {
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
          _FleetRow? homeFleet,
          List<_FleetLocationNode> locations,
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

  bool _isMerchant(String typeId) {
    final stats = NavalStatsCatalog.get(typeId);
    return stats.cargoHold > 0;
  }

  double _shipStrength(String typeId) {
    final stats = NavalStatsCatalog.get(typeId);
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

      final isHomeFleet =
          capitalRegionId != null &&
          capitalProvinceLocalId != null &&
          !isAtSea &&
          regionId == capitalRegionId &&
          inPortId != null &&
          (inPortId == capitalProvinceLocalId ||
              inPortId == '$capitalRegionId|$capitalProvinceLocalId');

      String locationLabel;
      String? tileKey;
      String locationKey;
      if (isAtSea) {
        final seaZoneId = fleet.seaZoneId!;
        final zoneKey = seaZoneId.contains('|')
            ? seaZoneId
            : '$regionId|$seaZoneId';
        final zoneLabel = zoneKey.contains('|')
            ? zoneKey.split('|').last
            : zoneKey;
        locationLabel = '${unitsPanelRegionLabel(regionId)} — $zoneLabel';
        tileKey = tileKeyForSeaZoneLocation(game, regionId, zoneKey);
        locationKey = 'sea:$zoneKey';
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
          isAtSea: true,
          locationKey: locationKey,
          seaZoneId: zoneKey,
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
          isAtSea: false,
          locationKey: locationKey,
          inPortAtProvinceId: inPortId,
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
          isAtSea: false,
          locationKey: 'port:${province.regionId}|${province.id}',
          inPortAtProvinceId: '$capitalRegionId|$capitalProvinceLocalId',
        );
      }
    }

    final locations = <_FleetLocationNode>[];

    final provinceIds = ports.keys.toList()..sort();
    for (final fullProvinceId in provinceIds) {
      final provinceMap = provinceByRegionAndId[regionId] ?? const {};
      final province = provinceMap[fullProvinceId];
      if (province == null) continue;
      final fleets = ports[fullProvinceId]!
        ..sort((a, b) => a.label.compareTo(b.label));
      locations.add(_PortLocationNode(province: province, fleets: fleets));
    }

    final seaZoneKeys = seas.keys.toList()..sort();
    for (final zoneKey in seaZoneKeys) {
      final zoneLabel = zoneKey.contains('|')
          ? zoneKey.split('|').last
          : zoneKey;
      final fleets = seas[zoneKey]!..sort((a, b) => a.label.compareTo(b.label));
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

class NavalUnitsPanel extends StatefulWidget {
  const NavalUnitsPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
  });

  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;

  @override
  State<NavalUnitsPanel> createState() => _NavalUnitsPanelState();
}

class _NavalUnitsPanelState extends State<NavalUnitsPanel> {
  String? _combineTargetFleetId;
  final Set<String> _selectedForCombine = {};

  bool _isCombineModeActive() => _combineTargetFleetId != null;

  _FleetRow? _getTargetRow() {
    if (_combineTargetFleetId == null) return null;
    final tree = _buildNavalTree(widget.game, widget.humanPlayerId);
    final allRows = _flattenTree(tree);
    for (final row in allRows) {
      if (row.fleetId == _combineTargetFleetId) {
        return row;
      }
    }
    return null;
  }

  bool _isEligibleForCombine(_FleetRow row) {
    final targetRow = _getTargetRow();
    if (targetRow == null) return false;
    if (row.isHomeFleet) return false;
    if (row.fleetId == targetRow.fleetId) return false;
    return row.locationKey == targetRow.locationKey;
  }

  void _startCombine(_FleetRow row) {
    setState(() {
      _combineTargetFleetId = row.fleetId;
      _selectedForCombine.clear();
    });
  }

  void _toggleFleetForCombine(_FleetRow row) {
    setState(() {
      if (_selectedForCombine.contains(row.fleetId)) {
        _selectedForCombine.remove(row.fleetId);
      } else {
        _selectedForCombine.add(row.fleetId);
      }
    });
  }

  void _confirmCombine() {
    if (_combineTargetFleetId == null) return;

    final targetFleet = widget.game.worldState.fleets.firstWhere(
      (f) => f.id == _combineTargetFleetId,
      orElse: () => widget.game.worldState.fleets.first,
    );

    final fleetsToCombine = <Fleet>[targetFleet];
    for (final fleetId in _selectedForCombine) {
      final fleet = widget.game.worldState.fleets.firstWhere(
        (f) => f.id == fleetId,
        orElse: () => widget.game.worldState.fleets.first,
      );
      fleetsToCombine.add(fleet);
    }

    final allShips = <String>[];
    for (final fleet in fleetsToCombine) {
      allShips.addAll(fleet.shipTypeIds);
    }

    final updatedTarget = targetFleet.copyWith(shipTypeIds: allShips);
    final sourceFleetIds = _selectedForCombine.toSet();

    final updatedFleets = widget.game.worldState.fleets
        .where((f) => !sourceFleetIds.contains(f.id))
        .map((f) => f.id == _combineTargetFleetId ? updatedTarget : f)
        .toList();

    final newGame = widget.game.copyWith(
      worldState: widget.game.worldState.copyWith(fleets: updatedFleets),
    );

    _cancelCombine();
    widget.bus.emit(NavalFleetsUpdatedEvent(game: newGame));
  }

  void _cancelCombine() {
    setState(() {
      _combineTargetFleetId = null;
      _selectedForCombine.clear();
    });
  }

  void _openSplitDialog(_FleetRow row) {
    final fleet = widget.game.worldState.fleets.firstWhere(
      (f) => f.id == row.fleetId,
      orElse: () => widget.game.worldState.fleets.first,
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => SplitFleetDialog(
        originalFleet: fleet,
        game: widget.game,
        humanPlayerId: widget.humanPlayerId,
        isHomeFleet: row.isHomeFleet,
        onConfirm: (shipsToNewFleet) {
          _performSplit(fleet, shipsToNewFleet);
        },
      ),
    );
  }

  void _performSplit(Fleet originalFleet, List<String> shipsToNewFleet) {
    if (shipsToNewFleet.isEmpty) return;

    final shipsToNewSet = shipsToNewFleet.toSet();
    final remainingShips = originalFleet.shipTypeIds
        .where((s) => !shipsToNewSet.contains(s))
        .toList();

    final allFleetIds = widget.game.worldState.fleets
        .map((f) => int.tryParse(f.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final maxId = allFleetIds.isEmpty
        ? 0
        : allFleetIds.reduce((a, b) => a > b ? a : b);
    final newFleetId = '${maxId + 1}';

    final newFleet = Fleet(
      id: newFleetId,
      ownerId: widget.humanPlayerId,
      seaZoneId: originalFleet.seaZoneId,
      inPortAtProvinceId: originalFleet.inPortAtProvinceId,
      regionId: originalFleet.regionId,
      shipTypeIds: shipsToNewFleet,
      mission: FleetMission.none,
    );

    final updatedOriginal = originalFleet.copyWith(shipTypeIds: remainingShips);

    final List<Fleet> updatedFleets = [
      ...widget.game.worldState.fleets.where((f) => f.id != originalFleet.id),
      if (remainingShips.isNotEmpty) updatedOriginal,
      newFleet,
    ];

    final newGame = widget.game.copyWith(
      worldState: widget.game.worldState.copyWith(fleets: updatedFleets),
    );

    widget.bus.emit(NavalFleetsUpdatedEvent(game: newGame));
  }

  @override
  Widget build(BuildContext context) {
    final tree = _buildNavalTree(widget.game, widget.humanPlayerId);
    final hasAny = tree.any(
      (group) => group.homeFleet != null || group.locations.isNotEmpty,
    );

    return GestureDetector(
      onTap: _isCombineModeActive() ? _cancelCombine : null,
      behavior: HitTestBehavior.translucent,
      child: UnitsPanelShell(
        title: 'Naval Units',
        actions: [
          if (_isCombineModeActive())
            TextButton(onPressed: _cancelCombine, child: const Text('Cancel')),
        ],
        hasContent: hasAny,
        listChildren: [
          for (final group in tree) ...[
            RegionSectionHeader(label: unitsPanelRegionLabel(group.regionId)),
            if (group.homeFleet != null)
              _FleetExpansionTile(
                row: group.homeFleet!,
                onTap: group.homeFleet!.tileKey != null
                    ? () => widget.bus.emit(
                        LocateMapTileEvent(
                          tileKey: group.homeFleet!.tileKey!,
                          regionId: group.homeFleet!.regionId,
                        ),
                      )
                    : null,
                isCombineMode: _isCombineModeActive(),
                isCombineTarget:
                    _combineTargetFleetId == group.homeFleet!.fleetId,
                isSelectedForCombine: _selectedForCombine.contains(
                  group.homeFleet!.fleetId,
                ),
                isEligibleForCombine:
                    _isCombineModeActive() &&
                    _isEligibleForCombine(group.homeFleet!),
                onCombineStart: () => _startCombine(group.homeFleet!),
                onCombineToggle: () => _toggleFleetForCombine(group.homeFleet!),
                onCombineConfirm: () => _confirmCombine(),
                onSplitFleet: () => _openSplitDialog(group.homeFleet!),
                isSplitAllowed: true,
              ),
            for (final loc in group.locations) ...[
              LocationSectionHeader(
                label: loc.displayLabel,
                regionLabel: unitsPanelRegionLabel(loc.regionId),
              ),
              for (final row in loc.fleets)
                _FleetExpansionTile(
                  row: row,
                  onTap: row.tileKey != null
                      ? () => widget.bus.emit(
                          LocateMapTileEvent(
                            tileKey: row.tileKey!,
                            regionId: row.regionId,
                          ),
                        )
                      : null,
                  isCombineMode: _isCombineModeActive(),
                  isCombineTarget: _combineTargetFleetId == row.fleetId,
                  isSelectedForCombine: _selectedForCombine.contains(
                    row.fleetId,
                  ),
                  isEligibleForCombine:
                      _isCombineModeActive() && _isEligibleForCombine(row),
                  onCombineStart: () => _startCombine(row),
                  onCombineToggle: () => _toggleFleetForCombine(row),
                  onCombineConfirm: () => _confirmCombine(),
                  onSplitFleet: () => _openSplitDialog(row),
                  isSplitAllowed: true,
                ),
            ],
          ],
        ],
        emptyMessage: 'No naval units',
      ),
    );
  }
}

class _FleetExpansionTile extends StatelessWidget {
  const _FleetExpansionTile({
    required this.row,
    this.onTap,
    this.isCombineMode = false,
    this.isCombineTarget = false,
    this.isSelectedForCombine = false,
    this.isEligibleForCombine = false,
    this.onCombineStart,
    this.onCombineToggle,
    this.onCombineConfirm,
    this.onSplitFleet,
    this.isSplitAllowed = false,
  });

  final _FleetRow row;
  final VoidCallback? onTap;
  final bool isCombineMode;
  final bool isCombineTarget;
  final bool isSelectedForCombine;
  final bool isEligibleForCombine;
  final VoidCallback? onCombineStart;
  final VoidCallback? onCombineToggle;
  final VoidCallback? onCombineConfirm;
  final VoidCallback? onSplitFleet;
  final bool isSplitAllowed;

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
    final bool showCheckbox =
        isCombineMode && !isCombineTarget && isEligibleForCombine;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: showCheckbox ? onCombineToggle : onTap,
        child: ExpansionTile(
          title: Row(
            children: [
              if (showCheckbox) ...[
                Checkbox(
                  value: isSelectedForCombine,
                  onChanged: (_) => onCombineToggle?.call(),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(row.label, overflow: TextOverflow.ellipsis)),
              if (isCombineTarget) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'TARGET',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Locate fleet',
                  onPressed: onTap,
                  icon: const Icon(Icons.my_location),
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          subtitle: Text(
            '${row.locationLabel}\nMission: ${row.missionLabel} · ${_summary()}',
          ),
          dense: true,
          initiallyExpanded: isCombineMode,
          children: [
            if (row.shipCountsByType.isEmpty)
              const ListTile(title: Text('No ships in this fleet'), dense: true)
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
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isSplitAllowed) ...[
                    CtNinePatchButton(
                      onPressed: onSplitFleet,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minHeight: 36,
                      child: const Text('Split'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (!row.isHomeFleet)
                    CtNinePatchButton(
                      onPressed: isCombineTarget
                          ? onCombineConfirm
                          : isCombineMode
                          ? onCombineToggle
                          : onCombineStart,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minHeight: 36,
                      child: Text(
                        isCombineTarget
                            ? 'Confirm'
                            : isCombineMode
                            ? (isSelectedForCombine ? 'Remove' : 'Select')
                            : 'Combine',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
