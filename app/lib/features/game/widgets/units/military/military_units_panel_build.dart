import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import '../../../../../core/services/app_event_bus_panel_nav.dart';
import '../../panels/tree_builders/military_tree_builder.dart';
import '../shared/base_units_panel.dart';
import '../shared/location_section_header.dart';
import '../shared/region_labels.dart';
import '../shared/region_section_header.dart';
import 'military_units_panel.dart';
import 'military_units_panel_dialogs.dart';
import 'military_units_panel_support_army_tile.dart';
import 'military_units_panel_support_detail_rows.dart';

mixin MilitaryUnitsPanelBuild
    on BaseUnitsPanelState<MilitaryUnitsPanel>, MilitaryUnitsPanelDialogs {
  Widget buildMilitaryUnitsPanel(BuildContext context) {
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
      selectableIds: armyIds(flat),
      selectAllTooltip: l10n.military_units_selectAllArmies,
      deselectAllTooltip: l10n.military_units_deselectAllArmies,
      combineLabel: l10n.common_combine,
      canCombine: canCombine,
      onSelectAll: () => selectAllOrClear(armyIds(flat)),
      onCombine: () => performCombine(flat),
      trailingActions: [
        CtActionTextButton(
          primary: true,
          onPressed: readOnly ? null : openTrainDialog,
          enabled: !readOnly,
          label: l10n.common_train,
        ),
      ],
      hasContent: hasAny,
      listChildren: militaryListChildren(groups, l10n),
      emptyMessage: l10n.military_units_empty,
    );
  }

  List<Widget> militaryListChildren(
    List<RegionMilitaryGroup> groups,
    AppLocalizations l10n,
  ) {
    return [
      for (final group in groups) ...[
        RegionSectionHeader(
          label: regionDisplayLabel(group.regionKey),
          variant: RegionHeaderVariant.leftBar,
        ),
        ...buildProvinceLocationChildren(group, l10n),
        ...buildSeaLocationChildren(group, l10n),
      ],
    ];
  }

  List<Widget> buildProvinceLocationChildren(
    RegionMilitaryGroup group,
    AppLocalizations l10n,
  ) {
    return [
      for (final loc in group.provinces) ...[
        LocationSectionHeader(
          label: loc.displayLabel,
          regionLabel: regionDisplayLabel(loc.regionId),
        ),
        for (final block in loc.armies) buildArmyTile(block, l10n),
      ],
    ];
  }

  Widget buildArmyTile(ArmyBlock block, AppLocalizations l10n) {
    return MilitaryArmyExpansionTile(
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
      onLocate: armyLocateCallback(block),
      onSplit: widget.readOnly || block.army.regimentUnitIds.length < 2
          ? null
          : () => openSplitDialog(block),
      onMove:
          widget.readOnly ||
              block.army.isHomeArmy ||
              block.army.regimentUnitIds.isEmpty
          ? null
          : () => openMoveDialog(block),
    );
  }

  VoidCallback? armyLocateCallback(ArmyBlock block) {
    if (block.rows.isEmpty || block.rows.first.tileKey == null) {
      return null;
    }
    return () => emitLocateMapTile(
      tileKey: block.rows.first.tileKey!,
      regionId: block.regionKey,
    );
  }

  List<Widget> buildSeaLocationChildren(
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
          MilitaryShipDetailRow(
            row: row,
            l10n: l10n,
            onTap: row.tileKey == null
                ? null
                : () => emitLocateMapTile(
                    tileKey: row.tileKey!,
                    regionId: row.regionId,
                  ),
          ),
      ],
    ];
  }

  void emitLocateMapTile({required String tileKey, required String regionId}) {
    widget.bus.closePanelThenEmit(
      LocateMapTileEvent(tileKey: tileKey, regionId: regionId),
    );
  }
}
