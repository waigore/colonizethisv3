import 'package:flutter/material.dart';

import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';

/// Shows the "End turn?" confirmation dialog.
Future<bool?> showNextTurnConfirmationDialog(
  BuildContext context, {
  required int currentTurn,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('End turn?', style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Turn $currentTurn will end. Continue?'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CtNinePatchButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('No'),
              ),
              const SizedBox(width: 8),
              CtNinePatchButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

