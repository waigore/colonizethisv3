import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_spacing.dart';
import 'diplomacy_dialogs_grant_subsidy_chrome_labels.dart';

/// Centered minus/amount/plus row matching `.stepper` in the DIPL20001 mockup.
class GrantSubsidyAmountStepper extends StatelessWidget {
  const GrantSubsidyAmountStepper({
    required this.amount,
    required this.amountText,
    required this.canAdjust,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int amount;
  final String amountText;
  final bool canAdjust;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GrantSubsidyStepperButton(
          buttonKey: const Key('diplo_amount_minus'),
          label: '\u2212',
          enabled: canAdjust,
          background: EditorialMonoclePalette.bgDeep,
          borderColor: EditorialMonoclePalette.border,
          labelColor: EditorialMonoclePalette.muted,
          onTap: onDecrement,
        ),
        const SizedBox(width: 14),
        GrantSubsidyAmountLabel(text: amountText),
        const SizedBox(width: 14),
        GrantSubsidyStepperButton(
          buttonKey: const Key('diplo_amount_plus'),
          label: '+',
          enabled: canAdjust,
          background: EditorialMonoclePalette.surfaceLite,
          borderColor: EditorialMonoclePalette.accentDim,
          labelColor: EditorialMonoclePalette.accent,
          onTap: onIncrement,
        ),
      ],
    );
  }
}

/// Bespoke stepper button. The mockup uses sharp 1 dp borders and monospace
/// `−` / `+` glyphs (not Material icons), so a `GestureDetector` over a
/// `DecoratedBox` reproduces the chrome with the disable opacity convention
/// used by the rest of the dark catalog.
class GrantSubsidyStepperButton extends StatelessWidget {
  const GrantSubsidyStepperButton({
    required this.buttonKey,
    required this.label,
    required this.enabled,
    required this.background,
    required this.borderColor,
    required this.labelColor,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final bool enabled;
  final Color background;
  final Color borderColor;
  final Color labelColor;
  final VoidCallback onTap;

  static const double _minWidth = 40;
  static const double _height = 36;
  static const double _disabledOpacity = 0.3;

  @override
  Widget build(BuildContext context) {
    final Widget body = Container(
      constraints: const BoxConstraints(
        minWidth: _minWidth,
        minHeight: _height,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: CtSpacing.m,
      ),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: labelColor,
          fontFamily: 'monospace',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
    return Opacity(
      key: buttonKey,
      opacity: enabled ? 1.0 : _disabledOpacity,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: body,
      ),
    );
  }
}
