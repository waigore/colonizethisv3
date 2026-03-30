// Dialogs for diplomacy actions that require parameters. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';

/// Grant or Subsidy dialog widget. Emits [GrantOrSubsidySubmittedEvent] on submit.
class GrantOrSubsidyDialog extends StatelessWidget {
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

  int get _treasury {
    for (final p in game.players) {
      if (p.id == humanPlayerId) return p.treasury;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return CtDialogShell(
      child: _GrantSubsidyAmountBody(
        title: isSubsidy ? 'Set subsidy' : 'Grant aid',
        treasury: _treasury,
        isSubsidy: isSubsidy,
        onCancel: () => Navigator.of(context).pop(),
        onSubmit: (amount) {
          Navigator.of(context).pop();
          bus.emit(
            GrantOrSubsidySubmittedEvent(
              targetFactionId: targetFactionId,
              amount: amount,
              isSubsidy: isSubsidy,
            ),
          );
        },
      ),
    );
  }
}

class _GrantSubsidyAmountBody extends StatefulWidget {
  const _GrantSubsidyAmountBody({
    required this.title,
    required this.treasury,
    required this.isSubsidy,
    required this.onCancel,
    required this.onSubmit,
  });

  final String title;
  final int treasury;
  final bool isSubsidy;
  final VoidCallback onCancel;
  final void Function(int amount) onSubmit;

  @override
  State<_GrantSubsidyAmountBody> createState() =>
      _GrantSubsidyAmountBodyState();
}

class _GrantSubsidyAmountBodyState extends State<_GrantSubsidyAmountBody> {
  late int _amount;

  int get _step =>
      widget.isSubsidy ? setSubsidyAmountStep : grantAidAmountStep;

  int _maxAffordable() {
    final t = widget.treasury;
    final s = _step;
    if (t < s) return 0;
    return (t ~/ s) * s;
  }

  int _initialAmount() {
    final maxA = _maxAffordable();
    if (maxA < _step) return 0;
    final d =
        widget.isSubsidy ? setSubsidyDefaultAmount : grantAidDefaultAmount;
    final capped = d > maxA ? maxA : d;
    final snapped = (capped ~/ _step) * _step;
    if (snapped >= _step) return snapped;
    return (maxA ~/ _step) * _step;
  }

  bool get _canSubmit =>
      _amount >= _step &&
      _amount <= widget.treasury &&
      _amount % _step == 0;

  @override
  void initState() {
    super.initState();
    _amount = _initialAmount();
  }

  void _decrement() {
    final maxA = _maxAffordable();
    if (maxA < _step) return;
    setState(() {
      final next = _amount - _step;
      _amount = next < _step ? _step : next;
      if (_amount > maxA) _amount = maxA;
    });
  }

  void _increment() {
    final maxA = _maxAffordable();
    if (maxA < _step) return;
    setState(() {
      final next = _amount + _step;
      _amount = next > maxA ? maxA : next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxA = _maxAffordable();
    final canAdjust = maxA >= _step;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Treasury: £${widget.treasury}. Step: £$_step.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: const Key('diplo_amount_minus'),
              onPressed: canAdjust ? _decrement : null,
              icon: const Icon(Icons.remove),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '£$_amount',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              key: const Key('diplo_amount_plus'),
              onPressed: canAdjust ? _increment : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (!canAdjust)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Treasury is below the minimum valid amount (£$_step).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CtNinePatchButton(
              onPressed: widget.onCancel,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            CtNinePatchButton(
              enabled: _canSubmit,
              onPressed: () => widget.onSubmit(_amount),
              child: const Text('Submit'),
            ),
          ],
        ),
      ],
    );
  }
}

