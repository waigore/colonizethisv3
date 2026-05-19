import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import 'utils/naval_tree_builder.dart';
import 'units/shared/units_entity_action_row.dart';

class FleetExpansionTile extends StatelessWidget {
  const FleetExpansionTile({
    super.key,
    required this.row,
    required this.l10n,
    this.onTap,
    required this.isSelectedForCombine,
    this.combineSelectionEnabled = true,
    required this.onCombineSelectionToggle,
    this.onSplitFleet,
    this.onMoveFleet,
    this.isSplitAllowed = false,
  });

  final FleetRow row;
  final AppLocalizations l10n;
  final VoidCallback? onTap;
  final bool isSelectedForCombine;
  final bool combineSelectionEnabled;
  final VoidCallback onCombineSelectionToggle;
  final VoidCallback? onSplitFleet;
  final VoidCallback? onMoveFleet;
  final bool isSplitAllowed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ExpansionTile(
        title: _buildTitle(context),
        subtitle: _buildSubtitle(),
        dense: true,
        children: _buildChildren(),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return UnitsEntityActionRow(
      details: _buildTitleDetails(),
      actions: _buildTitleActions(),
    );
  }

  Widget _buildTitleDetails() {
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
        if (onTap != null) ...[
          const SizedBox(width: 4),
          IconButton(
            tooltip: l10n.naval_units_locateFleet,
            onPressed: onTap,
            icon: const Icon(Icons.my_location),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }

  List<UnitsEntityAction> _buildTitleActions() {
    final actions = <UnitsEntityAction>[];
    if (onMoveFleet != null) {
      actions.add(
        UnitsEntityAction(
          tooltip: l10n.common_move,
          icon: Icons.route,
          label: l10n.common_move,
          onPressed: onMoveFleet,
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
        ),
      );
    }
    return actions;
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(row.locationLabel),
        Text(l10n.naval_units_mission(row.missionLabel)),
        if (row.draftNavalMoveLine != null) Text(row.draftNavalMoveLine!),
      ],
    );
  }

  List<Widget> _buildChildren() {
    final children = <Widget>[
      ..._buildShipCountTiles(),
      ListTile(
        title: Text(l10n.naval_units_strength(row.strength.toStringAsFixed(1))),
        dense: true,
      ),
      ListTile(title: Text(l10n.naval_units_totalShips(row.totalShips))),
      if (row.warshipCount > 0)
        ListTile(title: Text(l10n.naval_units_warships(row.warshipCount))),
      if (row.merchantCount > 0)
        ListTile(title: Text(l10n.naval_units_merchants(row.merchantCount))),
      ListTile(
        title: Text(
          row.isHomeFleet
              ? l10n.naval_units_cargoCapacity(row.cargoCapacity)
              : l10n.naval_units_cargoCapacityIfAssigned(row.cargoCapacity),
        ),
        dense: true,
      ),
    ];
    return children;
  }

  List<Widget> _buildShipCountTiles() {
    if (row.shipCountsByType.isEmpty) {
      return [
        ListTile(title: Text(l10n.naval_units_noShipsInFleet), dense: true),
      ];
    }
    return [
      for (final entry in row.shipCountsByType.entries)
        ListTile(
          title: Text(
            l10n.naval_units_shipTypeCount(
              shipTypeDisplayName(entry.key),
              entry.value,
            ),
          ),
          dense: true,
        ),
    ];
  }
}
