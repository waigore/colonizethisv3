import 'package:flutter/material.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';

/// Shows the "End turn?" confirmation dialog (DLG60001).
///
/// SPEC: SPEC/ui/next-turn-confirmation.md — title in `--accent`, body in
/// `--fg`, both actions use `CtNinePatchButton` brass styling. No Material
/// chrome (`AlertDialog`, `TextButton`).
Future<bool?> showNextTurnConfirmationDialog(
  BuildContext context, {
  required int currentTurn,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final l10n = appL10n(ctx);
      final titleStyle = (theme.textTheme.titleMedium ?? const TextStyle())
          .copyWith(color: EditorialMonoclePalette.accent);
      final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
          .copyWith(color: EditorialMonoclePalette.fg);
      return CtDialogShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.game_nextTurnConfirm_title, style: titleStyle),
            const SizedBox(height: 8),
            Text(l10n.game_nextTurnConfirm_body(currentTurn), style: bodyStyle),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CtNinePatchButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.common_no),
                ),
                const SizedBox(width: 8),
                CtNinePatchButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(l10n.common_yes),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
