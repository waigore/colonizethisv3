// Read-only campaign parameters. SPEC/ui/in-game-shell-narrow.md § Game Parameters.

import 'package:flutter/material.dart';

import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_gap.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

/// Shows immutable setup flags for the active game session.
class GameParametersDialog extends StatelessWidget {
  const GameParametersDialog({
    super.key,
    required this.infiniteMode,
  });

  final bool infiniteMode;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final infiniteValue = infiniteMode
        ? l10n.gameParameters_infiniteModeOn
        : l10n.gameParameters_infiniteModeOff;

    return CtDialogShell(
      maxWidth: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.gameParameters_title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          CtGap.ml,
          Text(
            l10n.gameParameters_infiniteModeLine(infiniteValue),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          CtGap.l,
          Align(
            alignment: Alignment.centerRight,
            child: CtNinePatchButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.common_close),
            ),
          ),
        ],
      ),
    );
  }
}
