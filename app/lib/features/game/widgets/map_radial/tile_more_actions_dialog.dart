/// MAP30002 More tile actions dialog. SPEC/ui/tile-more-actions-dialog.md.
library;

import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'tile_radial_catalog.dart';
import 'tile_radial_keys.dart';
import 'tile_radial_spoke_view.dart';

/// Overflow list: Province details plus catalog remainder.
class TileMoreActionsDialog extends StatelessWidget {
  const TileMoreActionsDialog({
    required this.placeLine,
    required this.remainder,
    required this.onAction,
    required this.onProvinceDetails,
    super.key,
  });

  static const screenId = UiScreenIds.tileMoreActionsDialog;

  final String placeLine;
  final List<TileRadialSpokeView> remainder;
  final ValueChanged<TileRadialCatalogAction> onAction;
  final VoidCallback onProvinceDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return CtDialogShell(
      maxWidth: 360,
      child: Padding(
        padding: const EdgeInsets.all(CtSpacing.l),
        child: Column(
          key: kTileMoreActionsDialogKey,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.tileRadial_moreTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: EditorialMonoclePalette.accent,
              ),
            ),
            const SizedBox(height: CtSpacing.s),
            Text(
              placeLine,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: EditorialMonoclePalette.muted,
              ),
            ),
            const SizedBox(height: CtSpacing.m),
            _MoreRow(
              rowKey: kTileMoreProvinceDetailsKey,
              label: l10n.tileRadial_provinceDetails,
              enabled: true,
              onTap: onProvinceDetails,
            ),
            for (final row in remainder)
              _MoreRow(
                rowKey: tileRadialSpokeKey(row.action),
                label: row.label,
                caption: row.caption,
                tooltip: row.tooltip,
                enabled: row.enabled,
                onTap: row.enabled ? () => onAction(row.action) : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({
    required this.rowKey,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.tooltip,
    this.caption,
  });

  final Key rowKey;
  final String label;
  final String? caption;
  final String? tooltip;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: enabled
                ? EditorialMonoclePalette.fg
                : EditorialMonoclePalette.muted,
          ),
        ),
        if (caption != null && caption!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              caption!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: EditorialMonoclePalette.muted,
              ),
            ),
          ),
      ],
    );
    final labeled = (tooltip == null || tooltip!.isEmpty)
        ? texts
        : Tooltip(
            message: tooltip!,
            triggerMode: enabled
                ? TooltipTriggerMode.longPress
                : TooltipTriggerMode.tap,
            child: texts,
          );
    return GestureDetector(
      key: rowKey,
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CtSpacing.m),
        child: labeled,
      ),
    );
  }
}
