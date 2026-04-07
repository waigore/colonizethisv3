// Military units panel. SPEC/ui/military-units-panel.md, SPEC/ui/military-units-army-management.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_event_handler_scope.dart'
    show trainMilitaryDialogId;
import '../../../widgets/ct_nine_patch_button.dart';
import 'utils/military_tree_builder.dart';
import 'move_army_dialog.dart';
import 'split_army_dialog.dart';
import 'units/shared/location_section_header.dart';
import 'units/shared/region_section_header.dart';
import 'units/shared/units_panel_region_label.dart';
import 'units/shared/units_panel_shell.dart';

class MilitaryUnitsPanel extends StatefulWidget {
  const MilitaryUnitsPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    required this.topology,
    required this.draftOrders,
  });

  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;
  final MapTopology topology;
  final Orders draftOrders;

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

  bool? _headerSelectAllValue(List<ArmyBlock> flat) {
    if (flat.isEmpty) return false;
    final n = flat.length;
    final sel = _selectedArmyIds.length;
    if (sel == 0) return false;
    if (sel == n) return true;
    return null;
  }

  void _onHeaderSelectAllTapped(List<ArmyBlock> flat) {
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

  void _performCombine(List<ArmyBlock> flat) {
    if (!canCombineArmySelection(flat, _selectedArmyIds)) return;
    final ids = _selectedArmyIds.toList()..sort();
    widget.bus.emit(
      ArmyCombineRequestedEvent(
        humanPlayerId: widget.humanPlayerId,
        armyIds: ids,
      ),
    );
    setState(() => _selectedArmyIds.clear());
  }

  void _openSplitDialog(ArmyBlock block) {
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

  void _openMoveDialog(ArmyBlock block) {
    showDialog<void>(
      context: context,
      builder: (ctx) => MoveArmyDialog(
        army: block.army,
        game: widget.game,
        humanPlayerId: widget.humanPlayerId,
        bus: widget.bus,
        topology: widget.topology,
        draftOrders: widget.draftOrders,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = buildMilitaryGroups(widget.game, widget.humanPlayerId);
    final flat = flattenMilitaryArmyBlocks(groups);
    final hasAny = groups.isNotEmpty;
    final canCombine = canCombineArmySelection(flat, _selectedArmyIds);
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
                stationedProvinceDisplayLabel:
                    armyStationedProvinceDisplayLabel(widget.game, block.army),
                draftArmyMoveLine: armyDraftMoveLineForArmy(
                  game: widget.game,
                  humanPlayerId: widget.humanPlayerId,
                  armyId: block.army.id,
                  draftOrders: widget.draftOrders,
                ),
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
    required this.stationedProvinceDisplayLabel,
    this.draftArmyMoveLine,
    required this.isSelectedForCombine,
    required this.onCombineSelectionToggle,
    this.onLocate,
    this.onSplit,
    this.onMove,
  });

  final ArmyBlock block;
  final String stationedProvinceDisplayLabel;
  final String? draftArmyMoveLine;
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
          '$stationedProvinceDisplayLabel'
          '${draftArmyMoveLine != null ? '\n$draftArmyMoveLine' : ''}',
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

  final RegimentTypeRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ListTile(
        title: Text('${regimentTypeDisplayName(row.typeId)}: ${row.count}'),
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

  final MilitarySeaShipRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ListTile(
        title: Text('${shipTypeDisplayName(row.typeId)}: ${row.count}'),
        subtitle: Text('Status: ${row.statusLabel}'),
        dense: true,
        onTap: onTap,
      ),
    );
  }
}
