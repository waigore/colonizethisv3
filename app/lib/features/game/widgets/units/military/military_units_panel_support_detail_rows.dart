/// Army/ship detail row widgets. SPEC/ui/military-units-panel.md.

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
