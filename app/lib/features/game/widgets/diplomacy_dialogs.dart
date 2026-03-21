// Dialogs for diplomacy actions that require parameters. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';

/// Grant or Subsidy dialog widget. Emits [GrantOrSubsidySubmittedEvent] on submit.
class GrantOrSubsidyDialog extends StatefulWidget {
  const GrantOrSubsidyDialog({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.targetFactionId,
    required this.isSubsidy,
    required this.bus,
  });

  final Game game;
  final String humanPlayerId;
  final String targetFactionId;
  final bool isSubsidy;
  final AppEventBus bus;

  @override
  State<GrantOrSubsidyDialog> createState() => _GrantOrSubsidyDialogState();
}

class _GrantOrSubsidyDialogState extends State<GrantOrSubsidyDialog> {
  late final TextEditingController _controller;

  int get _treasury {
    for (final p in widget.game.players) {
      if (p.id == widget.humanPlayerId) return p.treasury;
    }
    return 0;
  }

  String get _title => widget.isSubsidy ? 'Set subsidy' : 'Grant aid';

  String get _hint => 'Amount (£). Treasury: £$_treasury';

  void _doSubmit() {
    final text = _controller.text.trim();
    final amount = int.tryParse(text);
    if (amount == null || amount <= 0) return;
    if (amount > _treasury) return;
    Navigator.of(context).pop();
    widget.bus.emit(
      GrantOrSubsidySubmittedEvent(
        targetFactionId: widget.targetFactionId,
        amount: amount,
        isSubsidy: widget.isSubsidy,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Amount', hintText: _hint),
            onSubmitted: (_) => _doSubmit(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CtNinePatchButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              CtNinePatchButton(
                onPressed: _doSubmit,
                child: const Text('Submit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
          Text(title, style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Amount', hintText: hint),
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
