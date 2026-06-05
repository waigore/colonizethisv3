import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';

import '../../../config/ct_e2e.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_spacing.dart';
import 'utils/naval_tree_builder.dart';
import 'units/shared/units_entity_action_row.dart';

/// Naval-units fleet row.
///
/// Implements `Refs #2866` S8 mockup-fidelity gaps R25–R29 (see
/// `SPEC/ui/naval-units-panel.md` § *Naval mockup fidelity (R25–R29)* and
/// `SPEC/ui/mockups/UNIT30001-naval-units-panel.html`):
/// - R25 — actions render through [UnitsEntityActionRow] with
///   `dense: true`, so Move / Split / Locate stay on a single inline row
///   at the default panel width.
/// - R26 — when [FleetRow.isHomeFleet] is `true`, the title appends a
///   compact uppercase `HOME` chip styled with `--accent-dim` / `--bg-deep`
///   tokens.
/// - R27 — the locate control lives at the **right end** of the actions
///   cluster (icon-only `CtNinePatchButton` via
///   [UnitsEntityAction.iconOnly]); regular fleets get Move + Split + Locate,
///   Home Fleets get Split + Locate (Move stays hidden per R19).
/// - R28 — the localised `(in port)` / `(at sea)` qualifier is built into
///   [FleetRow.locationLabel] by `naval_tree_builder.dart`; this widget just
///   renders that subtitle.
/// - R29 — the expanded children render a single composition `Table` with
///   columns `Type | ×Count | Role`, an optional Home-Fleet
///   `Cargo capacity: X holds` line, and a single-line
///   `Total ships: X · Warships: Y · Merchants: Z` summary plus the
///   retained `Strength: V` line, replacing the previous per-stat
///   `ListTile` stack.
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
      padding: const EdgeInsets.only(left: CtSpacing.m),
      child: ExpansionTile(
        title: _buildTitle(),
        subtitle: _buildSubtitle(),
        dense: true,
        children: _buildChildren(),
      ),
    );
  }

  Widget _buildTitle() {
    return UnitsEntityActionRow(
      dense: true,
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
        if (row.isHomeFleet) ...[
          const SizedBox(width: 6),
          _HomeFleetChip(label: l10n.naval_units_homeFleetChip),
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
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          CtSpacing.l,
          4,
          CtSpacing.l,
          CtSpacing.m,
        ),
        child: _FleetExpandedContent(row: row, l10n: l10n),
      ),
    ];
  }
}

/// `HOME` chip rendered next to the Home Fleet name (Refs #2866 S8 R26;
/// mockup `.home-tag`). Tokens resolved from
/// [EditorialMonoclePalette] (`--accent-dim`, `--bg-deep`).
class _HomeFleetChip extends StatelessWidget {
  const _HomeFleetChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.accentDim,
        borderRadius: BorderRadius.circular(1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: EditorialMonoclePalette.bgDeep,
          fontFamily: 'monospace',
          fontSize: 8,
          letterSpacing: 0.5,
          fontFeatures: const [FontFeature.tabularFigures()],
          height: 1.0,
        ),
      ),
    );
  }
}

/// Expanded composition view for a fleet row (Refs #2866 S8 R29; mockup
/// `.fleet-row .f-expanded`).
///
/// Renders a single `Table` with one row per ship type, an optional
/// Home-Fleet cargo line, and a single-line composition summary
/// (`Total ships: X · Warships: Y · Merchants: Z`) plus the retained
/// `Strength: V` line — replacing the previous per-stat `ListTile` stack.
class _FleetExpandedContent extends StatelessWidget {
  const _FleetExpandedContent({required this.row, required this.l10n});

  final FleetRow row;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final styles = _ExpandedStyles.create();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildShipsBlock(styles),
        if (row.isHomeFleet) ...[
          const SizedBox(height: 4),
          Text(
            l10n.naval_units_cargoCapacityHolds(row.cargoCapacity),
            style: styles.cap,
          ),
        ],
        const SizedBox(height: 2),
        Text(
          l10n.naval_units_compositionSummary(
            row.totalShips,
            row.warshipCount,
            row.merchantCount,
          ),
          style: styles.stats,
        ),
        Text(
          l10n.naval_units_strength(row.strength.toStringAsFixed(1)),
          style: styles.stats,
        ),
      ],
    );
  }

  Widget _buildShipsBlock(_ExpandedStyles styles) {
    final ships = row.shipCountsByType;
    if (ships.isEmpty) {
      return Text(
        l10n.naval_units_noShipsInFleet,
        style: styles.label.copyWith(color: EditorialMonoclePalette.muted),
      );
    }
    return Table(
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: IntrinsicColumnWidth(),
      },
      border: TableBorder(
        horizontalInside: BorderSide(
          color: EditorialMonoclePalette.border,
          width: 1,
        ),
        bottom: BorderSide(
          color: EditorialMonoclePalette.border,
          width: 1,
        ),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (final entry in ships.entries)
          TableRow(
            children: [
              _cell(
                Text(shipTypeDisplayName(entry.key), style: styles.label),
              ),
              _cell(
                Text(
                  l10n.naval_units_compositionCount(entry.value),
                  style: styles.count,
                  textAlign: TextAlign.right,
                ),
                align: Alignment.centerRight,
              ),
              _cell(Text(_roleLabelFor(entry.key), style: styles.role)),
            ],
          ),
      ],
    );
  }

  Widget _cell(Widget child, {AlignmentGeometry align = Alignment.centerLeft}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: CtSpacing.xs,
      ),
      child: Align(alignment: align, child: child),
    );
  }

  String _roleLabelFor(String typeId) {
    final stats = NavalStatsCatalog.get(typeId);
    return stats.cargoHold > 0
        ? l10n.naval_units_compositionRoleMerchant
        : l10n.naval_units_compositionRoleWarship;
  }
}

class _ExpandedStyles {
  const _ExpandedStyles({
    required this.label,
    required this.count,
    required this.role,
    required this.cap,
    required this.stats,
  });

  factory _ExpandedStyles.create() {
    const mono = 'monospace';
    return _ExpandedStyles(
      label: TextStyle(
        fontFamily: mono,
        fontSize: 9,
        color: EditorialMonoclePalette.fg,
      ),
      count: TextStyle(
        fontFamily: mono,
        fontSize: 9,
        color: EditorialMonoclePalette.accentDim,
      ),
      role: TextStyle(
        fontFamily: mono,
        fontSize: 7,
        color: EditorialMonoclePalette.muted,
      ),
      cap: TextStyle(fontSize: 9, color: EditorialMonoclePalette.accentDim),
      stats: TextStyle(
        fontFamily: mono,
        fontSize: 9,
        color: EditorialMonoclePalette.muted,
      ),
    );
  }

  final TextStyle label;
  final TextStyle count;
  final TextStyle role;
  final TextStyle cap;
  final TextStyle stats;
}
