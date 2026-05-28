import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';

/// Show the Android-back exit-to-main-menu confirmation dialog.
///
/// SPEC: `SPEC/ui/in-game-shell-narrow.md` § Android back confirm. The
/// returned [Future] resolves to `true` when the player confirms `Exit`,
/// `false` when they tap `Cancel` or dismiss the barrier.
///
/// Visual contract:
///   * `barrierColor` resolves to [EditorialMonoclePalette.dialogScrim] —
///     the canonical `--dialog-scrim` token, matching the universal
///     dark-overlay scrim used by every modal on the editorial-monocle
///     theme (`SPEC/ui/pixel-art-ui-catalog.md` § Dialog scrim).
///   * The title renders in `--accent` (display font slot).
///   * The body renders in `--fg`.
///   * The `Exit` destructive action renders its label in `--danger`
///     (`EditorialMonoclePalette.danger`) so the destructive intent is
///     visually distinct from `Cancel`, which keeps the default brass
///     label color.
Future<bool> showExitToMainMenuConfirmDialog(BuildContext context) async {
  final bool? shouldExit = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true,
    barrierColor: EditorialMonoclePalette.dialogScrim,
    builder: (BuildContext ctx) => const ExitConfirmDialog(),
  );
  return shouldExit ?? false;
}

/// The static dialog body for the exit-to-main-menu confirmation prompt.
///
/// Extracted as a `StatelessWidget` so the dialog can be exercised in
/// widget tests and Widgetbook stories without driving Android back
/// interception. Returns `true` / `false` via the surrounding
/// `Navigator.pop` calls.
class ExitConfirmDialog extends StatelessWidget {
  const ExitConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle? titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: EditorialMonoclePalette.accent,
      fontWeight: FontWeight.w700,
    );
    final TextStyle? bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: EditorialMonoclePalette.fg,
    );
    final TextStyle? exitLabelStyle = theme.textTheme.titleSmall?.copyWith(
      color: EditorialMonoclePalette.danger,
      fontWeight: FontWeight.w700,
    );

    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.game_exitConfirm_title, style: titleStyle),
          const SizedBox(height: 8),
          Text(l10n.game_exitConfirm_body, style: bodyStyle),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              CtNinePatchButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.common_cancel),
              ),
              const SizedBox(width: 8),
              CtNinePatchButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  l10n.game_exitConfirm_exit,
                  style: exitLabelStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
