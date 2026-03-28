// Dialogs for diplomacy actions that require parameters. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_logic/colonizethis_logic.dart';
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
  late int _amount;

  int get _treasury {
    for (final p in widget.game.players) {
      if (p.id == widget.humanPlayerId) return p.treasury;
    }
    return 0;
  }

  int get _step =>
      widget.isSubsidy ? setSubsidyAmountStep : grantAidAmountStep;

  int get _min =>
      widget.isSubsidy ? setSubsidyAmountStep : grantAidAmountStep;

  int get _default =>
      widget.isSubsidy ? setSubsidyDefaultAmount : grantAidDefaultAmount;

  String get _title => widget.isSubsidy ? 'Set subsidy' : 'Grant aid';

  bool get _canSubmit {
    if (_amount < _min || _amount > _treasury) return false;
    if (widget.isSubsidy) {
      return _amount % setSubsidyAmountStep == 0;
    }
    return _amount % grantAidAmountStep == 0;
  }

  void _adjust(int delta) {
    final next = _amount + delta;
    if (next < _min || next > _treasury) return;
    setState(() => _amount = next);
  }

  void _doSubmit() {
    if (!_canSubmit) return;
    Navigator.of(context).pop();
    widget.bus.emit(
      GrantOrSubsidySubmittedEvent(
        targetFactionId: widget.targetFactionId,
        amount: _amount,
        isSubsidy: widget.isSubsidy,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final d = _default;
    _amount = d > _treasury ? (_treasury ~/ _step) * _step : d;
    if (_amount < _min) {
      _amount = _min;
    }
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
          Text(
            'Treasury: £$_treasury · step £$_step',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _amount - _step >= _min
                    ? () => _adjust(-_step)
                    : null,
                icon: const Icon(Icons.remove),
                tooltip: 'Decrease',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '£$_amount',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                onPressed: _amount + _step <= _treasury
                    ? () => _adjust(_step)
                    : null,
                icon: const Icon(Icons.add),
                tooltip: 'Increase',
              ),
            ],
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
                onPressed: _canSubmit ? _doSubmit : null,
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
  final step = isSubsidy ? setSubsidyAmountStep : grantAidAmountStep;
  final min = step;
  final defaultAmount = isSubsidy ? setSubsidyDefaultAmount : grantAidDefaultAmount;
  var amount = defaultAmount > treasury ? (treasury ~/ step) * step : defaultAmount;
  if (amount < min) amount = min;

  final title = isSubsidy ? 'Set subsidy' : 'Grant aid';

  void bump(StateSetter setState, int delta) {
    setState(() {
      final next = amount + delta;
      if (next >= min && next <= treasury) {
        amount = next;
      }
    });
  }

  showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final canSubmit =
            amount >= min &&
            amount <= treasury &&
            (isSubsidy
                ? amount % setSubsidyAmountStep == 0
                : amount % grantAidAmountStep == 0);
        return CtDialogShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Treasury: £$treasury · step £$step',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed:
                        amount - step >= min ? () => bump(setState, -step) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '£$amount',
                      style: Theme.of(ctx).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: amount + step <= treasury
                        ? () => bump(setState, step)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
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
                    onPressed: canSubmit
                        ? () {
                            Navigator.of(ctx).pop();
                            onSubmitted(amount);
                          }
                        : null,
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

int _treasuryFor(Game game, String playerId) {
  for (final p in game.players) {
    if (p.id == playerId) return p.treasury;
  }
  return 0;
}
