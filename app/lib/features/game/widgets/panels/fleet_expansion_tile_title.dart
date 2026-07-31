import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:flutter/material.dart';

import '../units/shared/units_entity_action_row.dart';
import 'fleet_expansion_tile.dart';
import 'fleet_expansion_tile_expanded.dart';

/// Collapsed fleet-row title/subtitle chrome for [FleetExpansionTile] (Refs #4117).
extension FleetExpansionTileTitle on FleetExpansionTile {
  Widget buildFleetTitleRow() {
    return UnitsEntityActionRow(
      chrome: false,
      dense: true,
      details: buildFleetTitleDetails(),
      actions: buildFleetTitleActions(),
    );
  }

  Widget buildFleetTitleDetails() {
    return Row(
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
        Flexible(child: Text(row.label, overflow: TextOverflow.ellipsis)),
        if (row.isHomeFleet) ...[
          const SizedBox(width: 6),
          HomeFleetChip(label: l10n.naval_units_homeFleetChip),
        ],
      ],
    );
  }

  List<UnitsEntityAction> buildFleetTitleActions() {
    final actions = <UnitsEntityAction>[];
    if (onMoveFleet != null) {
      actions.add(
        UnitsEntityAction(
          tooltip: l10n.common_move,
          icon: Icons.route,
          label: l10n.common_move,
          onPressed: onMoveFleet,
          buttonKey: kCtE2EFleetMoveActionKey,
        ),
      );
    }
    if (onAssignMission != null) {
      actions.add(
        UnitsEntityAction(
          tooltip: l10n.naval_mission_assign,
          icon: Icons.flag,
          label: l10n.naval_mission_assign,
          onPressed: onAssignMission,
          buttonKey: kCtE2EFleetMissionActionKey,
        ),
      );
    }
    if (isSplitAllowed) {
      actions.add(
        UnitsEntityAction(
          tooltip: l10n.common_split,
          icon: Icons.call_split,
          label: l10n.common_split,
          onPressed: onSplitFleet,
          buttonKey: kCtE2EFleetSplitActionKey,
        ),
      );
    }
    if (onTap != null) {
      actions.add(
        UnitsEntityAction(
          tooltip: l10n.naval_units_locateFleet,
          icon: Icons.my_location,
          label: l10n.naval_units_locateFleet,
          onPressed: onTap,
          iconOnly: true,
        ),
      );
    }
    return actions;
  }

  Widget buildFleetSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(row.locationLabel),
        Text(l10n.naval_units_mission(row.missionLabel)),
        if (row.draftNavalMoveLine != null) Text(row.draftNavalMoveLine!),
        if (row.draftNavalMissionLine != null) Text(row.draftNavalMissionLine!),
      ],
    );
  }
}
