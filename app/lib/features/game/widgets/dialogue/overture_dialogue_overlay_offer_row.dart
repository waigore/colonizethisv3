import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/ct_spacing.dart';
import 'dialogue_tristate_decision_row.dart';

/// Phase-2 offer row. Splits the offerer display name and the localized
/// stage label into two `Text` widgets so they can paint distinct
/// editorial-monocle palette colors per #2867 R22 (`--accent` for the
/// offerer, `--muted` for the stage label).
///
/// Accept / Reject affordances render as two mutually exclusive
/// `CtToggleSwitch` controls via [DialogueTristateDecisionRow] (Refs #2867 R22,
/// #4018). Submit stays disabled until every row has a non-null decision (R23).
class OvertureOfferRow extends StatelessWidget {
  const OvertureOfferRow({
    required this.rowIndex,
    required this.offerer,
    required this.stageLabel,
    required this.acceptLabel,
    required this.rejectLabel,
    required this.decision,
    required this.onDecisionChanged,
    super.key,
  });

  final int rowIndex;
  final String offerer;
  final String stageLabel;
  final String acceptLabel;
  final String rejectLabel;

  /// Current tristate decision: `null` (undecided) / `true` (accept) /
  /// `false` (reject).
  final bool? decision;

  /// Reports the next tristate decision. Callers should `setState` the
  /// owning `accepted[i]` list slot to the passed value (including
  /// `null` when the user reverts a previously-committed toggle).
  final ValueChanged<bool?> onDecisionChanged;

  /// Stable test-grep key for the Accept-side `CtToggleSwitch` in row N.
  static String acceptToggleKeyFor(int rowIndex) =>
      'overtureAcceptToggle_$rowIndex';

  /// Stable test-grep key for the Reject-side `CtToggleSwitch` in row N.
  static String rejectToggleKeyFor(int rowIndex) =>
      'overtureRejectToggle_$rowIndex';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CtSpacing.ml),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabelsRow(Theme.of(context)),
          const SizedBox(height: CtSpacing.m),
          DialogueTristateDecisionRow(
            positiveToggleKey: ValueKey<String>(acceptToggleKeyFor(rowIndex)),
            negativeToggleKey: ValueKey<String>(rejectToggleKeyFor(rowIndex)),
            positiveLabel: acceptLabel,
            negativeLabel: rejectLabel,
            decision: decision,
            onDecisionChanged: onDecisionChanged,
          ),
        ],
      ),
    );
  }

  /// Two-tone offerer/stage labels row. Extracted so `build` stays within
  /// the `repo.dart_file_non_comment_line_size` 60-line per-`build`
  /// budget when the row is hosted under the stacked
  /// `Column(Row + Wrap)` layout (issue #2870 S8 / S10).
  Widget _buildLabelsRow(ThemeData theme) {
    final TextStyle base =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final TextStyle offererStyle = base.copyWith(
      color: EditorialMonoclePalette.accent,
      fontWeight: FontWeight.w600,
    );
    final TextStyle separatorStyle = base.copyWith(
      color: EditorialMonoclePalette.muted,
    );
    final TextStyle stageStyle = base.copyWith(
      color: EditorialMonoclePalette.muted,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            offerer,
            key: const ValueKey<String>('overtureOfferOfferer'),
            style: offererStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          ': ',
          key: const ValueKey<String>('overtureOfferSeparator'),
          style: separatorStyle,
        ),
        Flexible(
          child: Text(
            stageLabel,
            key: const ValueKey<String>('overtureOfferStage'),
            style: stageStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
