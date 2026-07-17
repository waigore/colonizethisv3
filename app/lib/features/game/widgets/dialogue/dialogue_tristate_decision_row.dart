// Shared dual-toggle tristate decision row for overture / call-to-arms.
// Refs #4018 (#2867 R22 / R24 / R25).
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/ct_toggle_switch.dart';

/// True when every entry in [decisions] is non-null (Submit unlock).
bool dialogueTristateAllDecided(Iterable<bool?> decisions) {
  for (final value in decisions) {
    if (value == null) return false;
  }
  return true;
}

/// Dual mutually-exclusive `CtToggleSwitch` row for accept/join vs
/// reject/refuse with tristate `null` undecided semantics.
class DialogueTristateDecisionRow extends StatelessWidget {
  const DialogueTristateDecisionRow({
    required this.positiveToggleKey,
    required this.negativeToggleKey,
    required this.positiveLabel,
    required this.negativeLabel,
    required this.decision,
    required this.onDecisionChanged,
    super.key,
  });

  final Key positiveToggleKey;
  final Key negativeToggleKey;
  final String positiveLabel;
  final String negativeLabel;

  /// `null` undecided / `true` positive / `false` negative.
  final bool? decision;
  final ValueChanged<bool?> onDecisionChanged;

  @override
  Widget build(BuildContext context) {
    final TextStyle base =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 8,
      children: <Widget>[
        DialogueLabeledToggle(
          toggleKey: positiveToggleKey,
          label: positiveLabel,
          labelStyle: base.copyWith(color: EditorialMonoclePalette.success),
          value: decision == true,
          onGlowColor: EditorialMonoclePalette.success,
          onChanged: (bool turnedOn) {
            onDecisionChanged(turnedOn ? true : null);
          },
        ),
        DialogueLabeledToggle(
          toggleKey: negativeToggleKey,
          label: negativeLabel,
          labelStyle: base.copyWith(color: EditorialMonoclePalette.danger),
          value: decision == false,
          onGlowColor: EditorialMonoclePalette.danger,
          onChanged: (bool turnedOn) {
            onDecisionChanged(turnedOn ? false : null);
          },
        ),
      ],
    );
  }
}

/// `CtToggleSwitch` + colored label; tap on either toggles [value].
class DialogueLabeledToggle extends StatelessWidget {
  const DialogueLabeledToggle({
    required this.toggleKey,
    required this.label,
    required this.labelStyle,
    required this.value,
    required this.onGlowColor,
    required this.onChanged,
    super.key,
  });

  final Key toggleKey;
  final String label;
  final TextStyle labelStyle;
  final bool value;
  final Color onGlowColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          CtToggleSwitch(
            key: toggleKey,
            value: value,
            onGlowColor: onGlowColor,
            onChanged: onChanged,
          ),
          const SizedBox(width: CtSpacing.s),
          Text(label, style: labelStyle),
        ],
      ),
    );
  }
}
