/// Regiment/ship detail row widgets. SPEC/ui/military-units-panel.md.
///
/// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/ct_spacing.dart';
import '../../panels/tree_builders/military_tree_builder.dart';

class MilitaryRegimentRow extends StatelessWidget {
  const MilitaryRegimentRow({
    super.key,
    required this.row,
    required this.l10n,
    this.onTap,
  });

  final RegimentTypeRow row;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: CtSpacing.m),
      child: MilitaryUnitDetailRow(
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

class MilitaryShipRow extends StatelessWidget {
  const MilitaryShipRow({
    super.key,
    required this.row,
    required this.l10n,
    this.onTap,
  });

  final MilitarySeaShipRow row;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: CtSpacing.m),
      child: MilitaryUnitDetailRow(
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
/// rendered without Material `ListTile` chrome (Refs #2914 S8).
class MilitaryUnitDetailRow extends StatelessWidget {
  const MilitaryUnitDetailRow({
    super.key,
    required this.title,
    this.subtitle,
    this.onTap,
  });

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
