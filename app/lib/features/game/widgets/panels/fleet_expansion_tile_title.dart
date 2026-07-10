// Collapsed fleet-row title/subtitle chrome for [FleetExpansionTile].
// Split from `fleet_expansion_tile.dart` to keep the host under the repo
// file-size target (Refs #3878).

part of 'fleet_expansion_tile.dart';

extension _FleetExpansionTileTitle on FleetExpansionTile {
  Widget buildFleetTitleRow() {
    // `chrome: false`: the surrounding bordered gradient card is supplied by
    // [UnitsEntityCard] so the action row must not paint its own
    // [UnitsPanelRowChrome] border (issue #3514 AC-6).
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
          _HomeFleetChip(label: l10n.naval_units_homeFleetChip),
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
      ],
    );
  }
}
