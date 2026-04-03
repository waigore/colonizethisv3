// Military units panel. SPEC/ui/military-units-panel.md, SPEC/ui/military-units-army-management.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_event_handler_scope.dart'
    show trainMilitaryDialogId;
import '../../../widgets/ct_nine_patch_button.dart';
import '../utils/map_location_resolver.dart';
import '../utils/sea_zone_name_resolver.dart';
import 'move_army_dialog.dart';
import 'split_army_dialog.dart';
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

/// One regiment-type row under an army: type, count, medals, status.
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

abstract class _LocationNode {
  String get displayLabel;
  String get regionId;
}

/// Province with one or more armies (land).
class _ProvinceArmiesNode extends _LocationNode {
  _ProvinceArmiesNode({required this.province, required this.armies});

  final Province province;
  final List<_ArmyBlock> armies;

  @override
  String get displayLabel => province.displayName ?? province.id;

  @override
  String get regionId => province.regionId;
}

class _ArmyBlock {
  _ArmyBlock({required this.army, required this.rows, required this.regionKey});

  final Army army;
  final List<_RegimentTypeRow> rows;

  /// Panel region key: `oldWorld` / `newWorld` (matches [TileMapResult] regions).
  final String regionKey;
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

class _RegionMilitaryGroup {
  _RegionMilitaryGroup({
    required this.regionKey,
    required this.provinces,
    required this.seaLocations,
  });

  final String regionKey;
  final List<_ProvinceArmiesNode> provinces;
  final List<_SeaZoneLocationNode> seaLocations;
}

List<_RegimentTypeRow> _rowsForArmyUnits(
  Game game,
  Province province,
  List<Unit> units,
  String regionKey,
) {
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
        regionId: regionKey,
      ),
    );
  }
  return rows;
}

List<_RegionMilitaryGroup> _buildMilitaryGroups(
  Game game,
  String humanPlayerId,
) {
  final unitsById = <String, Unit>{
    for (final u in game.worldState.oldWorld.units) u.id: u,
    for (final u in game.worldState.newWorld.units) u.id: u,
  };

  final armies =
      game.worldState.armies
          .where((a) => a.ownerId == humanPlayerId)
          .where((a) => a.isHomeArmy || a.regimentUnitIds.isNotEmpty)
          .toList()
        ..sort((a, b) {
          if (a.isHomeArmy != b.isHomeArmy) {
            return a.isHomeArmy ? -1 : 1;
          }
          return a.id.compareTo(b.id);
        });

  final result = <_RegionMilitaryGroup>[];

  for (final regionEntry in {
    'oldWorld': game.worldState.oldWorld,
    'newWorld': game.worldState.newWorld,
  }.entries) {
    final regionKey = regionEntry.key;
    final regionData = regionEntry.value;

    final provinceById = {
      for (final p in regionData.provinces) '${p.regionId}|${p.id}': p,
      for (final p in regionData.provinces) p.id: p,
    };

    final armiesHere = armies.where((a) {
      final full = ProvinceId.isPrefixed(a.stationedProvinceId)
          ? a.stationedProvinceId
          : ProvinceId.full(regionKey, a.stationedProvinceId);
      final p = tryGetProvince(game.worldState, full);
      return p != null && p.regionId == regionKey;
    }).toList();

    final byProvince = <String, List<Army>>{};
    for (final a in armiesHere) {
      final pid = a.stationedProvinceId;
      final full = ProvinceId.isPrefixed(pid)
          ? pid
          : ProvinceId.full(regionKey, pid);
      byProvince.putIfAbsent(full, () => []).add(a);
    }

    final provinceNodes = <_ProvinceArmiesNode>[];
    final provinceIds = byProvince.keys.toList()..sort();
    for (final fullProvinceId in provinceIds) {
      final province = provinceById[fullProvinceId];
      if (province == null) continue;
      final list = byProvince[fullProvinceId]!;
      final blocks = <_ArmyBlock>[];
      for (final army in list) {
        final regUnits = <Unit>[
          for (final id in army.regimentUnitIds)
            if (unitsById[id] != null) unitsById[id]!,
        ];
        blocks.add(
          _ArmyBlock(
            army: army,
            rows: _rowsForArmyUnits(game, province, regUnits, regionKey),
            regionKey: regionKey,
          ),
        );
      }
      provinceNodes.add(
        _ProvinceArmiesNode(province: province, armies: blocks),
      );
    }

    final fleetsInRegion = game.worldState.fleets
        .where(
          (f) =>
              f.ownerId == humanPlayerId &&
              f.regionId == regionKey &&
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
          : '$regionKey|$seaZoneId';
      bySeaZone.putIfAbsent(zoneKey, () => []).add(f);
    }

    final seaLocations = <_SeaZoneLocationNode>[];
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
      final zoneLabel = seaZoneDisplayName(
        game: game,
        regionId: regionKey,
        seaZoneId: zoneKey,
      );
      final tileKey = tileKeyForSeaZoneLocation(game, regionKey, zoneKey);
      final rows = <_ShipTypeRow>[];
      for (final typeId in shipTypeIds.keys.toList()..sort()) {
        rows.add(
          _ShipTypeRow(
            typeId: typeId,
            count: shipTypeIds[typeId]!,
            statusLabel: _missionLabel(mission ?? FleetMission.none),
            tileKey: tileKey,
            regionId: regionKey,
          ),
        );
      }
      seaLocations.add(
        _SeaZoneLocationNode(
          seaZoneLabel: zoneLabel,
          regionId: regionKey,
          rows: rows,
        ),
      );
    }

    if (provinceNodes.isNotEmpty || seaLocations.isNotEmpty) {
      result.add(
        _RegionMilitaryGroup(
          regionKey: regionKey,
          provinces: provinceNodes,
          seaLocations: seaLocations,
        ),
      );
    }
  }

  return result;
}

List<_ArmyBlock> _flattenArmies(List<_RegionMilitaryGroup> groups) {
  final out = <_ArmyBlock>[];
  for (final g in groups) {
    for (final p in g.provinces) {
      out.addAll(p.armies);
    }
  }
  return out;
}

bool _canCombineArmySelection(
  List<_ArmyBlock> flat,
  Set<String> selectedArmyIds,
) {
  if (selectedArmyIds.length < 2) return false;
  final selected = flat
      .where((b) => selectedArmyIds.contains(b.army.id))
      .toList();
  if (selected.length < 2) return false;
  final province = selected.first.army.stationedProvinceId;
  return selected.every((b) => b.army.stationedProvinceId == province);
}

/// Panel that lists armies (land) and ships (sea) for the human player.
class MilitaryUnitsPanel extends StatefulWidget {
  const MilitaryUnitsPanel({
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
  State<MilitaryUnitsPanel> createState() => _MilitaryUnitsPanelState();
}

class _MilitaryUnitsPanelState extends State<MilitaryUnitsPanel> {
  final Set<String> _selectedArmyIds = {};

  void _toggleArmySelection(String armyId) {
    setState(() {
      if (_selectedArmyIds.contains(armyId)) {
        _selectedArmyIds.remove(armyId);
      } else {
        _selectedArmyIds.add(armyId);
      }
    });
  }

  bool? _headerSelectAllValue(List<_ArmyBlock> flat) {
    if (flat.isEmpty) return false;
    final n = flat.length;
    final sel = _selectedArmyIds.length;
    if (sel == 0) return false;
    if (sel == n) return true;
    return null;
  }

  void _onHeaderSelectAllTapped(List<_ArmyBlock> flat) {
    setState(() {
      final allSelected =
          flat.isNotEmpty &&
          flat.every((b) => _selectedArmyIds.contains(b.army.id));
      if (allSelected) {
        _selectedArmyIds.clear();
      } else {
        for (final b in flat) {
          _selectedArmyIds.add(b.army.id);
        }
      }
    });
  }

  void _performCombine(List<_ArmyBlock> flat) {
    if (!_canCombineArmySelection(flat, _selectedArmyIds)) return;
    final ids = _selectedArmyIds.toList()..sort();
    widget.bus.emit(
      ArmyCombineRequestedEvent(
        humanPlayerId: widget.humanPlayerId,
        armyIds: ids,
      ),
    );
    setState(() => _selectedArmyIds.clear());
  }

  void _openSplitDialog(_ArmyBlock block) {
    showDialog<void>(
      context: context,
      builder: (ctx) => SplitArmyDialog(
        army: block.army,
        game: widget.game,
        humanPlayerId: widget.humanPlayerId,
        bus: widget.bus,
        isHomeArmy: block.army.isHomeArmy,
      ),
    );
  }

  void _openMoveDialog(_ArmyBlock block) {
    showDialog<void>(
      context: context,
      builder: (ctx) => MoveArmyDialog(
        army: block.army,
        game: widget.game,
        humanPlayerId: widget.humanPlayerId,
        bus: widget.bus,
        topology: widget.topology,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _buildMilitaryGroups(widget.game, widget.humanPlayerId);
    final flat = _flattenArmies(groups);
    final hasAny = groups.isNotEmpty;
    final canCombine = _canCombineArmySelection(flat, _selectedArmyIds);
    final headerCheckbox = _headerSelectAllValue(flat);

    return UnitsPanelShell(
      title: 'Military Units',
      actions: [
        if (hasAny && flat.isNotEmpty) ...[
          Tooltip(
            message: headerCheckbox == true
                ? 'Deselect all armies'
                : 'Select all armies',
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
        CtNinePatchButton(
          onPressed: () {
            widget.bus.emit(const ClosePanelEvent());
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.bus.emit(OpenDialogEvent(trainMilitaryDialogId));
            });
          },
          child: const Text('Train'),
        ),
      ],
      hasContent: hasAny,
      listChildren: [
        for (final group in groups) ...[
          RegionSectionHeader(label: unitsPanelRegionLabel(group.regionKey)),
          for (final loc in group.provinces) ...[
            LocationSectionHeader(
              label: loc.displayLabel,
              regionLabel: unitsPanelRegionLabel(loc.regionId),
            ),
            for (final block in loc.armies)
              _ArmyExpansionTile(
                block: block,
                isSelectedForCombine: _selectedArmyIds.contains(block.army.id),
                onCombineSelectionToggle: () =>
                    _toggleArmySelection(block.army.id),
                onLocate:
                    block.rows.isNotEmpty && block.rows.first.tileKey != null
                    ? () {
                        widget.bus.emit(const ClosePanelEvent());
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          widget.bus.emit(
                            LocateMapTileEvent(
                              tileKey: block.rows.first.tileKey!,
                              regionId: block.regionKey,
                            ),
                          );
                        });
                      }
                    : null,
                onSplit: block.army.regimentUnitIds.length >= 2
                    ? () => _openSplitDialog(block)
                    : null,
                onMove:
                    !block.army.isHomeArmy &&
                        block.army.regimentUnitIds.isNotEmpty
                    ? () => _openMoveDialog(block)
                    : null,
              ),
          ],
          for (final loc in group.seaLocations) ...[
            LocationSectionHeader(
              label: loc.displayLabel,
              regionLabel: unitsPanelRegionLabel(loc.regionId),
            ),
            for (final row in loc.rows)
              _ShipRow(
                row: row,
                onTap: row.tileKey == null
                    ? null
                    : () {
                        widget.bus.emit(const ClosePanelEvent());
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          widget.bus.emit(
                            LocateMapTileEvent(
                              tileKey: row.tileKey!,
                              regionId: row.regionId,
                            ),
                          );
                        });
                      },
              ),
          ],
        ],
      ],
      emptyMessage: 'No military units',
    );
  }
}

class _ArmyExpansionTile extends StatelessWidget {
  const _ArmyExpansionTile({
    required this.block,
    required this.isSelectedForCombine,
    required this.onCombineSelectionToggle,
    this.onLocate,
    this.onSplit,
    this.onMove,
  });

  final _ArmyBlock block;
  final bool isSelectedForCombine;
  final VoidCallback onCombineSelectionToggle;
  final VoidCallback? onLocate;
  final VoidCallback? onSplit;
  final VoidCallback? onMove;

  String _armyTitle() {
    if (block.army.isHomeArmy) return 'Home Army';
    return 'Army ${block.army.id}';
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
            Flexible(
              child: Text(_armyTitle(), overflow: TextOverflow.ellipsis),
            ),
            if (onLocate != null) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Locate',
                onPressed: onLocate,
                icon: const Icon(Icons.my_location),
                iconSize: 18,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${block.army.regimentUnitIds.length} regiments · '
          '${block.army.stationedProvinceId}',
        ),
        dense: true,
        children: [
          if (block.rows.isEmpty)
            const ListTile(title: Text('No regiments assigned'), dense: true)
          else ...[
            for (final row in block.rows) _RegimentRow(row: row, onTap: null),
          ],
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onMove != null) ...[
                  CtNinePatchButton(
                    onPressed: onMove,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minHeight: 36,
                    child: const Text('Move'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (onSplit != null)
                  CtNinePatchButton(
                    onPressed: onSplit,
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
