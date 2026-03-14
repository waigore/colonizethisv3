// Dialogs for diplomacy actions that require parameters. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';

/// Shows a dialog to enter amount for Grant Aid or Set Subsidy, then calls [onSubmitted].
void showGrantOrSubsidyDialog({
  required BuildContext context,
  required Game game,
  required String humanPlayerId,
  required String targetFactionId,
  required bool isSubsidy,
  required void Function(int amount) onSubmitted,
}) {
  final treasury = _treasuryFor(game, humanPlayerId);
  final title = isSubsidy ? 'Set subsidy' : 'Grant aid';
  final hint = 'Amount (£). Treasury: £$treasury';

  final controller = TextEditingController(text: '100');

  void doSubmit(BuildContext ctx) {
    final text = controller.text.trim();
    final amount = int.tryParse(text);
    if (amount == null || amount <= 0) return;
    if (amount > treasury) return;
    Navigator.of(ctx).pop();
    onSubmitted(amount);
  }

  showDialog<void>(
    context: context,
    builder: (ctx) => CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(ctx).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount',
              hintText: hint,
            ),
            onSubmitted: (_) => doSubmit(ctx),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CtNinePatchButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              CtNinePatchButton(
                onPressed: () => doSubmit(ctx),
                child: const Text('Submit'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

int _treasuryFor(Game game, String playerId) {
  for (final p in game.players) {
    if (p.id == playerId) return p.treasury;
  }
  return 0;
}
