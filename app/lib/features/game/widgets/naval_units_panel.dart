// Naval units panel. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../widgets/ct_nine_patch_button.dart';
import '../utils/map_location_resolver.dart';
import '../utils/sea_zone_name_resolver.dart';
import 'move_fleet_dialog.dart';
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
          fleetId: homeFleetIdFor(humanPlayerId),
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
      final zoneLabel = seaZoneDisplayName(
        game: game,
        regionId: regionId,
        seaZoneId: zoneKey,
      );
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
    required this.topology,
  });

  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;
  final MapTopology topology;

  @override
  State<NavalUnitsPanel> createState() => _NavalUnitsPanelState();
}

class _NavalUnitsPanelState extends State<NavalUnitsPanel> {
  final Set<String> _selectedFleetIds = {};

  /// Canonical fleet id for combine/split selection (Home Fleet uses [homeFleetIdFor]).
  String _selectionFleetId(_FleetRow row) {
    if (row.isHomeFleet) return homeFleetIdFor(widget.humanPlayerId);
    return row.fleetId;
  }

  bool _canCombineSelection(List<_FleetRow> flat) {
    final rowsById = <String, _FleetRow>{
      for (final r in flat) _selectionFleetId(r): r,
    };
    final activeIds = _selectedFleetIds.where(rowsById.containsKey).toList();
    if (activeIds.length < 2) return false;
    String? locationKey;
    for (final id in activeIds) {
      final row = rowsById[id]!;
      locationKey ??= row.locationKey;
      if (row.locationKey != locationKey) return false;
    }
    return true;
  }

  String _combineTargetFleetId(List<_FleetRow> flat, Set<String> selected) {
    for (final row in flat) {
      final id = _selectionFleetId(row);
      if (!selected.contains(id)) continue;
      if (row.isHomeFleet) return id;
    }
    for (final row in flat) {
      final id = _selectionFleetId(row);
      if (selected.contains(id)) return id;
    }
    throw StateError('combine target: empty selection');
  }

  Fleet? _fleetForRow(_FleetRow row) {
    final id = _selectionFleetId(row);
    for (final f in widget.game.worldState.fleets) {
      if (f.id == id) return f;
    }
    if (row.isHomeFleet) {
      final portId = row.inPortAtProvinceId;
      if (portId == null) return null;
      return Fleet(
        id: id,
        ownerId: widget.humanPlayerId,
        regionId: row.regionId,
        inPortAtProvinceId: portId,
        ships: const [],
        mission: FleetMission.none,
      );
    }
    return null;
  }

  void _toggleFleetSelection(_FleetRow row) {
    setState(() {
      final id = _selectionFleetId(row);
      if (_selectedFleetIds.contains(id)) {
        _selectedFleetIds.remove(id);
      } else {
        _selectedFleetIds.add(id);
      }
    });
  }

  bool? _headerSelectAllValue(List<_FleetRow> flat) {
    if (flat.isEmpty) return false;
    final ids = flat.map(_selectionFleetId).toSet();
    var n = 0;
    for (final id in ids) {
      if (_selectedFleetIds.contains(id)) n++;
    }
    if (n == 0) return false;
    if (n == ids.length) return true;
    return null;
  }

  /// Select-all header: from none or partial → select every row; from all → clear.
  /// Does not rely on [Checkbox] tristate `next` (indeterminate taps may pass false).
  void _onHeaderSelectAllTapped(List<_FleetRow> flat) {
    setState(() {
      final ids = flat.map(_selectionFleetId).toSet();
      final allSelected =
          ids.isNotEmpty && ids.every(_selectedFleetIds.contains);
      if (allSelected) {
        _selectedFleetIds.clear();
      } else {
        _selectedFleetIds
          ..clear()
          ..addAll(ids);
      }
    });
  }

  void _performCombine(List<_FleetRow> flat) {
    if (!_canCombineSelection(flat)) return;

    final selected = Set<String>.from(_selectedFleetIds);
    final targetId = _combineTargetFleetId(flat, selected);

    _FleetRow? targetRow;
    for (final row in flat) {
      if (_selectionFleetId(row) == targetId) {
        targetRow = row;
        break;
      }
    }
    if (targetRow == null) return;

    final targetFleet = _fleetForRow(targetRow);
    if (targetFleet == null) return;

    final mergedShips = <ShipInstance>[...targetFleet.ships];
    for (final row in flat) {
      final id = _selectionFleetId(row);
      if (!selected.contains(id) || id == targetId) continue;
      final f = _fleetForRow(row);
      if (f != null) mergedShips.addAll(f.ships);
    }

    final merged = Fleet(
      id: targetId,
      ownerId: widget.humanPlayerId,
      seaZoneId: targetFleet.seaZoneId,
      inPortAtProvinceId: targetFleet.inPortAtProvinceId,
      regionId: targetFleet.regionId,
      ships: mergedShips,
      mission: FleetMission.none,
    );

    final homeId = homeFleetIdFor(widget.humanPlayerId);
    var updated = widget.game.worldState.fleets
        .where((f) => !selected.contains(f.id))
        .toList();
    updated = [...updated, merged];
    updated = updated
        .where((f) => f.ships.isNotEmpty || f.id == homeId)
        .toList();

    final newGame = widget.game.copyWith(
      worldState: widget.game.worldState.copyWith(fleets: updated),
    );

    setState(_selectedFleetIds.clear);
    widget.bus.emit(NavalFleetsUpdatedEvent(game: newGame));
  }

  @override
  void didUpdateWidget(covariant NavalUnitsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      final flat = _flattenTree(
        _buildNavalTree(widget.game, widget.humanPlayerId),
      );
      final valid = flat.map(_selectionFleetId).toSet();
      final pruned = _selectedFleetIds.intersection(valid);
      if (pruned.length != _selectedFleetIds.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _selectedFleetIds
              ..clear()
              ..addAll(pruned);
          });
        });
      }
    }
  }

  void _openSplitDialog(_FleetRow row) {
    final id = _selectionFleetId(row);
    Fleet? fleet;
    for (final f in widget.game.worldState.fleets) {
      if (f.id == id) {
        fleet = f;
        break;
      }
    }
    if (fleet == null) return;

    final original = fleet;
    showDialog<void>(
      context: context,
      builder: (ctx) => SplitFleetDialog(
        originalFleet: original,
        game: widget.game,
        humanPlayerId: widget.humanPlayerId,
        isHomeFleet: row.isHomeFleet,
        bus: widget.bus,
      ),
    );
  }

  void _openMoveFleetDialog(_FleetRow row) {
    if (row.isHomeFleet) return;
    Fleet? fleet;
    for (final f in widget.game.worldState.fleets) {
      if (f.id == row.fleetId) {
        fleet = f;
        break;
      }
    }
    final nonNullFleet = fleet;
    if (nonNullFleet == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => MoveFleetDialog(
        game: widget.game,
        topology: widget.topology,
        humanPlayerId: widget.humanPlayerId,
        fleet: nonNullFleet,
        bus: widget.bus,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant NavalUnitsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      final flat = _flattenTree(
        _buildNavalTree(widget.game, widget.humanPlayerId),
      );
      final valid = flat.map(_selectionFleetId).toSet();
      final pruned = _selectedFleetIds.intersection(valid);
      if (pruned.length != _selectedFleetIds.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _selectedFleetIds
              ..clear()
              ..addAll(pruned);
          });
        });
      }
    }
  }

  void _openSplitDialog(_FleetRow row) {
    final id = _selectionFleetId(row);
    Fleet? fleet;
    for (final f in widget.game.worldState.fleets) {
      if (f.id == id) {
        fleet = f;
        break;
      }
    }
    if (fleet == null) return;

    final original = fleet;
    showDialog<void>(
      context: context,
      builder: (ctx) => SplitFleetDialog(
        originalFleet: original,
        game: widget.game,
        humanPlayerId: widget.humanPlayerId,
        isHomeFleet: row.isHomeFleet,
        bus: widget.bus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tree = _buildNavalTree(widget.game, widget.humanPlayerId);
    final flat = _flattenTree(tree);
    final hasAny = tree.any(
      (group) => group.homeFleet != null || group.locations.isNotEmpty,
    );
    final canCombine = _canCombineSelection(flat);
    final headerCheckbox = _headerSelectAllValue(flat);

    return UnitsPanelShell(
      title: 'Naval Units',
      actions: [
        if (hasAny && flat.isNotEmpty) ...[
          Tooltip(
            message: headerCheckbox == true
                ? 'Deselect all fleets'
                : 'Select all fleets',
            child: Checkbox(
              tristate: true,
              value: headerCheckbox,
              onChanged: (_) => _onHeaderSelectAllTapped(flat),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 4),
          CtNinePatchButton(
            onPressed: canCombine ? () => _performCombine(flat) : null,
            enabled: canCombine,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minHeight: 32,
            child: const Text('Combine'),
          ),
        ],
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
              isSelectedForCombine: _selectedFleetIds.contains(
                _selectionFleetId(group.homeFleet!),
              ),
              onCombineSelectionToggle: () =>
                  _toggleFleetSelection(group.homeFleet!),
              onSplitFleet: () => _openSplitDialog(group.homeFleet!),
              onMoveFleet: null,
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
                isSelectedForCombine: _selectedFleetIds.contains(
                  _selectionFleetId(row),
                ),
                onCombineSelectionToggle: () => _toggleFleetSelection(row),
                onSplitFleet: () => _openSplitDialog(row),
                onMoveFleet: () => _openMoveFleetDialog(row),
                isSplitAllowed: true,
              ),
          ],
        ],
      ],
      emptyMessage: 'No naval units',
    );
  }
}

class _FleetExpansionTile extends StatelessWidget {
  const _FleetExpansionTile({
    required this.row,
    this.onTap,
    required this.isSelectedForCombine,
    required this.onCombineSelectionToggle,
    this.onSplitFleet,
    this.onMoveFleet,
    this.isSplitAllowed = false,
  });

  final _FleetRow row;
  final VoidCallback? onTap;
  final bool isSelectedForCombine;
  final VoidCallback onCombineSelectionToggle;
  final VoidCallback? onSplitFleet;
  final VoidCallback? onMoveFleet;
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
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Checkbox(
              value: isSelectedForCombine,
              onChanged: (_) => onCombineSelectionToggle(),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            Flexible(child: Text(row.label, overflow: TextOverflow.ellipsis)),
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
          if (isSplitAllowed)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onMoveFleet != null) ...[
                    CtNinePatchButton(
                      onPressed: onMoveFleet,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minHeight: 36,
                      child: const Text('Move'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  CtNinePatchButton(
                    onPressed: onSplitFleet,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minHeight: 36,
                    child: const Text('Split'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
