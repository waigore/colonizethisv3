/// Army expansion tile for the military units panel.
/// SPEC/ui/military-units-panel.md.

part of 'military_units_panel.dart';

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
