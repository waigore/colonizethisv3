/// Regiment/ship detail row widgets. SPEC/ui/military-units-panel.md.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
part of 'military_units_panel.dart';

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
