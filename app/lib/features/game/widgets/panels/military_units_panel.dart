// Military units panel. SPEC/ui/military-units-panel.md, SPEC/ui/military-units-army-management.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/ui_screen_ids.dart';
import '../../../../core/services/app_event_bus_panel_nav.dart';
import '../../../../core/services/app_event_handler_scope.dart'
    show trainMilitaryDialogId;
import '../../../../l10n/l10n.dart';
import '../../../../widgets/ct_spacing.dart';
import '../chrome/ct_action_text_button.dart';
import 'game_panel_contract.dart';
import '../utils/military_tree_builder.dart';
import '../unit_orders/move_army_dialog.dart';
import '../unit_orders/split_army_dialog.dart';
import '../units/shared/base_units_panel.dart';
import '../units/shared/location_section_header.dart';
import '../units/shared/region_section_header.dart';
import '../units/shared/units_entity_action_row.dart';
import '../units/shared/units_entity_card.dart';
import '../../utils/region_labels.dart';

part 'military_units_panel_support_detail_rows.dart';

class MilitaryUnitsPanel extends StatefulWidget with GamePanelMixin {
  const MilitaryUnitsPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    required this.topology,
    required this.draftOrders,
    this.readOnly = false,
  });

  /// SPEC/ui/military-units-panel.md — [UiScreenIds.militaryUnitsPanel].
  static const screenId = UiScreenIds.militaryUnitsPanel;

  @override
  final Game game;
  @override
  final String humanPlayerId;
  @override
  final AppEventBus bus;
  final MapTopology topology;
  final Orders draftOrders;
  @override
  final bool readOnly;

  @override
  State<MilitaryUnitsPanel> createState() => _MilitaryUnitsPanelState();
}

class _MilitaryUnitsPanelState
    extends BaseUnitsPanelState<MilitaryUnitsPanel> {
  Iterable<String> _armyIds(List<ArmyBlock> flat) =>
      flat.map((b) => b.army.id);

  void _performCombine(List<ArmyBlock> flat) {
    if (!canCombineArmySelection(flat, selection.selectedIds)) return;
    final ids = selection.selectedIds.toList()..sort();
    widget.bus.emit(
      ArmyCombineRequestedEvent(
        humanPlayerId: widget.humanPlayerId,
        armyIds: ids,
      ),
    );
    clearSelection();
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
    final playerView = buildPlayerView(
      widget.game,
      widget.topology,
      widget.humanPlayerId,
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => MoveArmyDialog(
        army: block.army,
        game: widget.game,
        humanPlayerId: widget.humanPlayerId,
        bus: widget.bus,
        topology: widget.topology,
        draftOrders: widget.draftOrders,
        playerView: playerView,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final groups = buildMilitaryGroups(widget.game, widget.humanPlayerId);
    final flat = flattenMilitaryArmyBlocks(groups);
    final hasAny = groups.isNotEmpty;
    final readOnly = widget.readOnly;
    final canCombine =
        !readOnly && canCombineArmySelection(flat, selection.selectedIds);

    // Shared select-all + Combine cluster per SPEC/ui/military-units-panel.md
    // § Header actions and issue #3514 owner decisions #5 / #15; the trailing
    // Train pill follows the cluster (`BaseUnitsPanelState.buildUnitsPanel`).
    return buildUnitsPanel(
      title: l10n.military_units_title,
      showCombineCluster: hasAny && flat.isNotEmpty && !readOnly,
      selectableIds: _armyIds(flat),
      selectAllTooltip: l10n.military_units_selectAllArmies,
      deselectAllTooltip: l10n.military_units_deselectAllArmies,
      combineLabel: l10n.common_combine,
      canCombine: canCombine,
      onSelectAll: () => selectAllOrClear(_armyIds(flat)),
      onCombine: () => _performCombine(flat),
      trailingActions: [
        CtActionTextButton(
          primary: true,
          onPressed: readOnly ? null : _openTrainDialog,
          enabled: !readOnly,
          label: l10n.common_train,
        ),
      ],
      hasContent: hasAny,
      listChildren: _buildListChildren(groups, l10n),
      emptyMessage: l10n.military_units_empty,
    );
  }

  void _openTrainDialog() {
    widget.bus.closePanelThenEmit(OpenDialogEvent(trainMilitaryDialogId));
  }

  List<Widget> _buildListChildren(
    List<RegionMilitaryGroup> groups,
    AppLocalizations l10n,
  ) {
    return [
      for (final group in groups) ...[
        RegionSectionHeader(
          label: regionDisplayLabel(group.regionKey),
          variant: RegionHeaderVariant.leftBar,
        ),
        ..._buildProvinceLocationChildren(group, l10n),
        ..._buildSeaLocationChildren(group, l10n),
      ],
    ];
  }

  List<Widget> _buildProvinceLocationChildren(
    RegionMilitaryGroup group,
    AppLocalizations l10n,
  ) {
    return [
      for (final loc in group.provinces) ...[
        LocationSectionHeader(
          label: loc.displayLabel,
          regionLabel: regionDisplayLabel(loc.regionId),
        ),
        for (final block in loc.armies) _buildArmyTile(block, l10n),
      ],
    ];
  }

  Widget _buildArmyTile(ArmyBlock block, AppLocalizations l10n) {
    return _ArmyExpansionTile(
      block: block,
      l10n: l10n,
      stationedProvinceDisplayLabel: armyStationedProvinceDisplayLabel(
        widget.game,
        block.army,
      ),
      draftArmyMoveLine: armyDraftMoveLineForArmy(
        game: widget.game,
        humanPlayerId: widget.humanPlayerId,
        armyId: block.army.id,
        draftOrders: widget.draftOrders,
      ),
      isSelectedForCombine: isSelected(block.army.id),
      combineSelectionEnabled: !widget.readOnly,
      onCombineSelectionToggle: () => toggleSelection(block.army.id),
      onLocate: _armyLocateCallback(block),
      onSplit: widget.readOnly || block.army.regimentUnitIds.length < 2
          ? null
          : () => _openSplitDialog(block),
      onMove:
          widget.readOnly ||
              block.army.isHomeArmy ||
              block.army.regimentUnitIds.isEmpty
          ? null
          : () => _openMoveDialog(block),
    );
  }

  VoidCallback? _armyLocateCallback(ArmyBlock block) {
    if (block.rows.isEmpty || block.rows.first.tileKey == null) {
      return null;
    }
    return () => _emitLocateMapTile(
      tileKey: block.rows.first.tileKey!,
      regionId: block.regionKey,
    );
  }

  List<Widget> _buildSeaLocationChildren(
    RegionMilitaryGroup group,
    AppLocalizations l10n,
  ) {
    return [
      for (final loc in group.seaLocations) ...[
        LocationSectionHeader(
          label: loc.displayLabel,
          regionLabel: regionDisplayLabel(loc.regionId),
        ),
        for (final row in loc.rows)
          _ShipRow(
            row: row,
            l10n: l10n,
            onTap: row.tileKey == null
                ? null
                : () => _emitLocateMapTile(
                    tileKey: row.tileKey!,
                    regionId: row.regionId,
                  ),
          ),
      ],
    ];
  }

  void _emitLocateMapTile({required String tileKey, required String regionId}) {
    widget.bus.closePanelThenEmit(
      LocateMapTileEvent(tileKey: tileKey, regionId: regionId),
    );
  }
}
