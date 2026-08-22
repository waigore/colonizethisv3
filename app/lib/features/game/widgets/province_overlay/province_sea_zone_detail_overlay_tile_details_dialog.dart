import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

/// Stable key for widget tests that open Tile details.
const Key kProvinceTileDetailsPanelKey = Key('province_tile_details_panel');

/// Named Tile details affordance (a11y / Widgetbook / tests).
const Key kProvinceTileDetailsActionKey = Key('province_tile_details_action');

/// Transport / connectivity text cluster that opens Tile details.
const Key kProvinceTileDetailsClusterKey = Key('province_tile_details_cluster');

/// Compact read-only Tile teaching dialog (Refs #4369).
@visibleForTesting
class ProvinceTileDetailsDialog extends StatelessWidget {
  const ProvinceTileDetailsDialog({
    super.key,
    required this.l10n,
    required this.lines,
  });

  final AppLocalizations l10n;
  final List<String> lines;

  static const Key closeButtonKey = Key('province_tile_details_close');

  @override
  Widget build(BuildContext context) {
    return CtDialogShell(
      maxWidth: 320,
      child: ProvinceTileDetailsPanel(
        l10n: l10n,
        lines: lines,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class ProvinceTileDetailsPanel extends StatelessWidget {
  const ProvinceTileDetailsPanel({
    super.key,
    required this.l10n,
    required this.lines,
    required this.onClose,
  });

  final AppLocalizations l10n;
  final List<String> lines;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.fg, height: 1.35);
    final captionStyle =
        (theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11)).copyWith(
          color: EditorialMonoclePalette.muted,
          height: 1.25,
        );
    return ConstrainedBox(
      key: kProvinceTileDetailsPanelKey,
      constraints: const BoxConstraints(maxHeight: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.provinceOverlay_tileDetailsTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: EditorialMonoclePalette.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: CtSpacing.m),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < lines.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == lines.length - 1 ? 0 : CtSpacing.s,
                      ),
                      child: Text(
                        lines[i],
                        style:
                            i == 0 ||
                                lines[i] ==
                                    l10n.provinceOverlay_tileRoadRailGloss
                            ? captionStyle
                            : bodyStyle,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: CtSpacing.ml),
          CtNinePatchButton(
            key: ProvinceTileDetailsDialog.closeButtonKey,
            onPressed: onClose,
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }
}
