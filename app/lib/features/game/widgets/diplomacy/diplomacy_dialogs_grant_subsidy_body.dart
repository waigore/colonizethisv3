import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import 'diplomacy_dialogs_grant_subsidy_chrome_labels.dart';
import 'diplomacy_dialogs_grant_subsidy_chrome_stepper.dart';

class GrantSubsidyAmountBody extends StatefulWidget {
  const GrantSubsidyAmountBody({super.key, 
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
  State<GrantSubsidyAmountBody> createState() =>
      GrantSubsidyAmountBodyState();
}

class GrantSubsidyAmountBodyState extends State<GrantSubsidyAmountBody> {
  late int _amount;

  int get _step =>
      widget.isSubsidy ? kSubsidyPercentStep : grantAidAmountStep;

  /// Lowest selectable value. Subsidy is a fixed 5% floor (Refs #3753 R3);
  /// Grant Aid uses the £ step as its floor.
  int get _min => widget.isSubsidy ? kSubsidyPercentMin : _step;

  /// Highest selectable value. Subsidy caps at 20% independent of treasury;
  /// Grant Aid caps at the largest affordable £ multiple.
  int _max() {
    if (widget.isSubsidy) return kSubsidyPercentMax;
    final t = widget.treasury;
    final s = _step;
    if (t < s) return 0;
    return (t ~/ s) * s;
  }

  int _initialAmount() {
    if (widget.isSubsidy) return kSubsidyPercentDefault;
    final maxA = _max();
    if (maxA < _step) return 0;
    final capped = grantAidDefaultAmount > maxA ? maxA : grantAidDefaultAmount;
    final snapped = (capped ~/ _step) * _step;
    if (snapped >= _step) return snapped;
    return (maxA ~/ _step) * _step;
  }

  bool get _canSubmit {
    if (widget.isSubsidy) return isValidSubsidyPercent(_amount);
    return _amount >= _step &&
        _amount <= widget.treasury &&
        _amount % _step == 0;
  }

  @override
  void initState() {
    super.initState();
    _amount = _initialAmount();
  }

  void _decrement() {
    final maxA = _max();
    if (maxA < _min) return;
    setState(() {
      final next = _amount - _step;
      _amount = next < _min ? _min : next;
      if (_amount > maxA) _amount = maxA;
    });
  }

  void _increment() {
    final maxA = _max();
    if (maxA < _min) return;
    setState(() {
      final next = _amount + _step;
      _amount = next > maxA ? maxA : next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final maxA = _max();
    final canAdjust = maxA >= _min;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GrantSubsidyDialogTitle(title: widget.title),
        const SizedBox(height: 10),
        GrantSubsidyTreasuryRow(
          // Subsidy is a treasury-independent percentage (Refs #3753 R3); show a
          // percent step line instead of the £ treasury/step copy used by grants.
          label: widget.isSubsidy
              ? l10n.diplomacy_subsidyStep(_step)
              : l10n.diplomacy_treasuryStep(widget.treasury, _step),
        ),
        const SizedBox(height: 10),
        const GrantSubsidyThinDivider(),
        CtGap.ml,
        GrantSubsidyAmountStepper(
          amount: _amount,
          amountText: widget.isSubsidy
              ? '$_amount%'
              : l10n.diplomacy_currencyAmount(_amount),
          canAdjust: canAdjust,
          onDecrement: _decrement,
          onIncrement: _increment,
        ),
        if (!canAdjust) ...[
          CtGap.m,
          GrantSubsidyBelowMinimumWarning(
            text: l10n.diplomacy_treasuryBelowMinimum(_step),
          ),
        ],
        CtGap.l,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CtNinePatchButton(
              onPressed: widget.onCancel,
              child: Text(l10n.common_cancel),
            ),
            CtGap.wm,
            CtNinePatchButton(
              enabled: _canSubmit,
              onPressed: () => widget.onSubmit(_amount),
              child: Text(l10n.game_callToArms_submit),
            ),
          ],
        ),
      ],
    );
  }
}
