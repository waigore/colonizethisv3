import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_spacing.dart';
import 'tree_builders/naval_tree_builder.dart';

/// `HOME` chip rendered next to the Home Fleet name (Refs #2866 S8 R26).
class HomeFleetChip extends StatelessWidget {
  const HomeFleetChip({super.key, required this.label});

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

/// Expanded composition view for a fleet row (Refs #2866 S8 R29).
class FleetExpandedContent extends StatelessWidget {
  const FleetExpandedContent({super.key, required this.row, required this.l10n});

  final FleetRow row;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final styles = FleetExpandedStyles.create();
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

  Widget _buildShipsBlock(FleetExpandedStyles styles) {
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

class FleetExpandedStyles {
  const FleetExpandedStyles({
    required this.label,
    required this.count,
    required this.role,
    required this.cap,
    required this.stats,
  });

  factory FleetExpandedStyles.create() {
    const mono = 'monospace';
    return FleetExpandedStyles(
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
