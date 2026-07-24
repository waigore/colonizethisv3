import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../panels/fleet_expansion_tile.dart';
import '../../panels/tree_builders/naval_tree_builder.dart';
import '../shared/base_units_panel.dart';
import '../shared/location_section_header.dart';
import '../shared/region_labels.dart';
import '../shared/region_section_header.dart';
import 'naval_units_panel.dart';
import 'naval_units_panel_state_base.dart';
import 'naval_units_panel_support_combine.dart';
import 'naval_units_panel_support_dialogs.dart';

mixin NavalUnitsPanelList
    on
        BaseUnitsPanelState<NavalUnitsPanel>,
        NavalUnitsPanelStateBase,
        NavalUnitsPanelCombine,
        NavalUnitsPanelDialogs {
  List<Widget> navalListChildren({
    required List<
      ({
        String regionId,
        FleetRow? homeFleet,
        List<NavalTreeLocationNode> locations,
      })
    >
    tree,
    required AppLocalizations l10n,
    required bool readOnly,
  }) {
    return [
      for (final group in tree) ...[
        RegionSectionHeader(
          label: regionDisplayLabel(group.regionId),
          variant: RegionHeaderVariant.leftBar,
        ),
        if (group.homeFleet != null)
          FleetExpansionTile(
            row: group.homeFleet!,
            l10n: l10n,
            onTap: group.homeFleet!.tileKey != null
                ? () => widget.bus.emit(
                    LocateMapTileEvent(
                      tileKey: group.homeFleet!.tileKey!,
                      regionId: group.homeFleet!.regionId,
                    ),
                  )
                : null,
            isSelectedForCombine: isSelected(
              selectionFleetId(group.homeFleet!),
            ),
            combineSelectionEnabled: !readOnly,
            onCombineSelectionToggle: () =>
                toggleFleetSelection(group.homeFleet!),
            onSplitFleet: readOnly
                ? null
                : () => openSplitDialog(group.homeFleet!),
            onMoveFleet: null,
            isSplitAllowed: !readOnly,
          ),
        for (final loc in group.locations) ...[
          LocationSectionHeader(
            label: loc.displayLabel,
            regionLabel: regionDisplayLabel(loc.regionId),
          ),
          for (final row in loc.fleets)
            FleetExpansionTile(
              row: row,
              l10n: l10n,
              onTap: row.tileKey != null
                  ? () => widget.bus.emit(
                      LocateMapTileEvent(
                        tileKey: row.tileKey!,
                        regionId: row.regionId,
                      ),
                    )
                  : null,
              isSelectedForCombine: isSelected(selectionFleetId(row)),
              combineSelectionEnabled: !readOnly,
              onCombineSelectionToggle: () => toggleFleetSelection(row),
              onSplitFleet: readOnly ? null : () => openSplitDialog(row),
              onMoveFleet: readOnly ? null : () => openMoveFleetDialog(row),
              isSplitAllowed: true,
            ),
        ],
      ],
    ];
  }
}
