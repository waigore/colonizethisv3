// Military units panel. SPEC/ui/military-units-panel.md, SPEC/ui/military-units-army-management.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/ui_screen_ids.dart';
import '../../../core/services/app_event_handler_scope.dart'
    show trainMilitaryDialogId;
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_spacing.dart';
import 'chrome/ct_action_text_button.dart';
import 'game_panel_contract.dart';
import 'utils/military_tree_builder.dart';
import 'move_army_dialog.dart';
import 'split_army_dialog.dart';
import 'units/shared/location_section_header.dart';
import 'units/shared/region_section_header.dart';
import 'units/shared/units_entity_action_row.dart';
import 'units/shared/units_entity_card.dart';
import 'units/shared/units_panel_shell.dart';
import '../utils/region_labels.dart';

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
    final canCombine =
        !widget.readOnly && canCombineArmySelection(flat, _selectedArmyIds);
    final headerCheckbox = _headerSelectAllValue(flat);
    final readOnly = widget.readOnly;

    return UnitsPanelShell(
      title: l10n.military_units_title,
      actions: _buildActions(
        l10n: l10n,
        hasAny: hasAny,
        flat: flat,
        canCombine: canCombine,
        headerCheckbox: headerCheckbox,
        readOnly: readOnly,
      ),
      hasContent: hasAny,
      listChildren: _buildListChildren(groups, l10n),
      emptyMessage: l10n.military_units_empty,
    );
  }

  List<Widget> _buildActions({
    required AppLocalizations l10n,
    required bool hasAny,
    required List<ArmyBlock> flat,
    required bool canCombine,
    required bool? headerCheckbox,
    required bool readOnly,
  }) {
    return [
      if (hasAny && flat.isNotEmpty && !readOnly) ...[
        Tooltip(
          message: headerCheckbox == true
              ? l10n.military_units_deselectAllArmies
              : l10n.military_units_selectAllArmies,
          child: Checkbox(
            tristate: true,
            value: headerCheckbox,
            onChanged: (_) => _onHeaderSelectAllTapped(flat),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 4),
        // Combine adopts the compact **primary** header pill
        // (`CtActionTextButton(primary: true)`) per SPEC/ui/military-units-panel.md
        // § Header actions and issue #3514 owner decisions #5 / #15.
        CtActionTextButton(
          primary: true,
          onPressed: canCombine ? () => _performCombine(flat) : null,
          enabled: canCombine,
          label: l10n.common_combine,
        ),
      ],
      CtActionTextButton(
        primary: true,
        onPressed: readOnly ? null : _openTrainDialog,
        enabled: !readOnly,
        label: l10n.common_train,
      ),
    ];
  }

  void _openTrainDialog() {
    widget.bus.emit(const ClosePanelEvent());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.bus.emit(OpenDialogEvent(trainMilitaryDialogId));
    });
  }

  List<Widget> _buildListChildren(
    List<RegionMilitaryGroup> groups,
    AppLocalizations l10n,
  ) {
    return [
      for (final group in groups) ...[
        RegionSectionHeader(label: regionDisplayLabel(group.regionKey)),
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
      isSelectedForCombine: _selectedArmyIds.contains(block.army.id),
      combineSelectionEnabled: !widget.readOnly,
      onCombineSelectionToggle: () => _toggleArmySelection(block.army.id),
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
    widget.bus.emit(const ClosePanelEvent());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.bus.emit(LocateMapTileEvent(tileKey: tileKey, regionId: regionId));
    });
  }
}

class _ArmyExpansionTile extends StatelessWidget {
  const _ArmyExpansionTile({
    required this.block,
    required this.l10n,
    required this.stationedProvinceDisplayLabel,
    this.draftArmyMoveLine,
    required this.isSelectedForCombine,
    required this.combineSelectionEnabled,
    required this.onCombineSelectionToggle,
    this.onLocate,
    this.onSplit,
    this.onMove,
  });

  final ArmyBlock block;
  final AppLocalizations l10n;
  final String stationedProvinceDisplayLabel;
  final String? draftArmyMoveLine;
  final bool isSelectedForCombine;
  final bool combineSelectionEnabled;
  final VoidCallback onCombineSelectionToggle;
  final VoidCallback? onLocate;
  final VoidCallback? onSplit;
  final VoidCallback? onMove;

  String _armyTitle() {
    if (block.army.isHomeArmy) return l10n.military_units_homeArmy;
    return l10n.military_units_army(block.army.id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: CtSpacing.m),
      child: UnitsEntityCard(
        title: _buildTitleRow(),
        subtitle: Text(_subtitleText()),
        children: _buildChildren(),
      ),
    );
  }

  Widget _buildTitleRow() {
    return UnitsEntityActionRow(
      chrome: false,
      details: Row(
        children: [
          Checkbox(
            value: isSelectedForCombine,
            onChanged: combineSelectionEnabled
                ? (_) => onCombineSelectionToggle()
                : null,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          Flexible(child: Text(_armyTitle(), overflow: TextOverflow.ellipsis)),
        ],
      ),
      // Issue #3514: Move / Split render as mockup compact pills and the Locate
      // control is the rightmost icon-only circular pill in the actions cluster
      // (moved out of the title `Row` / `CtIconAction`). Locate still emits the
      // same `LocateMapTileEvent` via [onLocate], so there is no behavioral
      // regression.
      actions: [
        if (onMove != null)
          UnitsEntityAction(
            tooltip: l10n.common_move,
            icon: Icons.route,
            label: l10n.common_move,
            onPressed: onMove,
          ),
        if (onSplit != null)
          UnitsEntityAction(
            tooltip: l10n.common_split,
            icon: Icons.call_split,
            label: l10n.common_split,
            onPressed: onSplit,
          ),
        if (onLocate != null)
          UnitsEntityAction(
            tooltip: l10n.common_locate,
            icon: Icons.my_location,
            label: l10n.common_locate,
            iconOnly: true,
            onPressed: onLocate,
          ),
      ],
    );
  }

  String _subtitleText() {
    if (draftArmyMoveLine == null) {
      return l10n.military_units_armySubtitle(
        block.army.regimentUnitIds.length,
        stationedProvinceDisplayLabel,
      );
    }
    return l10n.military_units_armySubtitleWithDraft(
      block.army.regimentUnitIds.length,
      stationedProvinceDisplayLabel,
      draftArmyMoveLine!,
    );
  }

  List<Widget> _buildChildren() {
    // Expanded content mirrors the mockup `.unit-row .u-comp-table` — the
    // per-regiment composition rows only. Move / Split are exposed exclusively
    // as the compact title-row pills (issue #3514 owner decision #6); the
    // legacy `CtNinePatchButton` footer duplicate is removed so the army card
    // carries no nine-patch row-action chrome.
    return [
      if (block.rows.isEmpty)
        _UnitDetailRow(title: l10n.military_units_noRegimentsAssigned)
      else
        for (final row in block.rows)
          _RegimentRow(row: row, l10n: l10n, onTap: null),
    ];
  }
}

class _RegimentRow extends StatelessWidget {
  const _RegimentRow({required this.row, required this.l10n, this.onTap});

  final RegimentTypeRow row;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: CtSpacing.m),
      child: _UnitDetailRow(
        title: l10n.military_units_typeCount(
          regimentTypeDisplayName(row.typeId),
          row.count,
        ),
        subtitle: l10n.military_units_regimentSubtitle(
          row.medalsSummary,
          row.statusLabel,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ShipRow extends StatelessWidget {
  const _ShipRow({required this.row, required this.l10n, this.onTap});

  final MilitarySeaShipRow row;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: CtSpacing.m),
      child: _UnitDetailRow(
        title: l10n.military_units_typeCount(
          shipTypeDisplayName(row.typeId),
          row.count,
        ),
        subtitle: l10n.military_units_status(row.statusLabel),
        onTap: onTap,
      ),
    );
  }
}

/// Dense per-type detail row (regiment / ship counts, empty-state notices)
/// rendered without Material `ListTile` chrome (Refs #2914 S8). Title and
/// optional subtitle resolve through the active editorial-monocle
/// `TextTheme` slots; an optional [onTap] surfaces the same tap affordance
/// the prior `ListTile(onTap:)` provided.
class _UnitDetailRow extends StatelessWidget {
  const _UnitDetailRow({required this.title, this.subtitle, this.onTap});

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleText = subtitle;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CtSpacing.l,
          vertical: CtSpacing.s,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: theme.textTheme.bodyMedium),
            if (subtitleText != null) ...[
              const SizedBox(height: CtSpacing.xs),
              Text(subtitleText, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
