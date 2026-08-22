import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_spacing.dart';
import 'dialogue_tristate_decision_row.dart';

/// One incoming Favored Trading Partner offer row (OVL90001).
class FtpDialogueOfferRow extends StatelessWidget {
  const FtpDialogueOfferRow({
    super.key,
    required this.rowIndex,
    required this.offererName,
    required this.acceptLabel,
    required this.rejectLabel,
    required this.acceptEffects,
    required this.rejectEffect,
    required this.decision,
    required this.onDecisionChanged,
  });

  final int rowIndex;
  final String offererName;
  final String acceptLabel;
  final String rejectLabel;
  final List<String> acceptEffects;
  final String rejectEffect;
  final bool? decision;
  final ValueChanged<bool?> onDecisionChanged;

  static String acceptToggleKeyFor(int rowIndex) => 'ftpAcceptToggle_$rowIndex';
  static String rejectToggleKeyFor(int rowIndex) => 'ftpRejectToggle_$rowIndex';

  @override
  Widget build(BuildContext context) {
    final TextStyle base =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final TextStyle muted = base.copyWith(color: EditorialMonoclePalette.muted);
    final TextStyle nameStyle =
        (Theme.of(context).textTheme.bodyMedium ??
                const TextStyle(fontSize: 14))
            .copyWith(
              color: EditorialMonoclePalette.accent,
              fontWeight: FontWeight.w600,
            );
    return Padding(
      padding: const EdgeInsets.only(bottom: CtSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(offererName, style: nameStyle),
          const SizedBox(height: CtSpacing.s),
          DialogueTristateDecisionRow(
            positiveToggleKey: ValueKey(acceptToggleKeyFor(rowIndex)),
            negativeToggleKey: ValueKey(rejectToggleKeyFor(rowIndex)),
            positiveLabel: acceptLabel,
            negativeLabel: rejectLabel,
            decision: decision,
            onDecisionChanged: onDecisionChanged,
          ),
          const SizedBox(height: CtSpacing.s),
          for (final line in acceptEffects) Text(line, style: muted),
          Text(rejectEffect, style: muted),
        ],
      ),
    );
  }
}
