part of 'fleet_expansion_tile.dart';

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
