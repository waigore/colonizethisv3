part of 'overture_dialogue_overlay.dart';

/// Phase-2 offer row. Splits the offerer display name and the localized
/// stage label into two `Text` widgets so they can paint distinct
/// editorial-monocle palette colors per #2867 R22 (`--accent` for the
/// offerer, `--muted` for the stage label).
///
/// Accept / Reject affordances render as two mutually exclusive
/// `CtToggleSwitch` controls (Refs #2867 R22). The Accept toggle uses
/// the `--success` glow when active; the Reject toggle uses the `--danger`
/// glow when active. The toggles are wired tristate-aware: tapping a
/// currently-off toggle commits the row to that decision and turns the
/// other side off; tapping a currently-on toggle reverts the row to the
/// undecided (`null`) state, preserving the #2867 R23 contract that
/// Submit is disabled until every row has a non-null decision.
class _OvertureOfferRow extends StatelessWidget {
  const _OvertureOfferRow({
    required this.rowIndex,
    required this.offerer,
    required this.stageLabel,
    required this.acceptLabel,
    required this.rejectLabel,
    required this.decision,
    required this.onDecisionChanged,
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
  /// owning `_accepted[i]` list slot to the passed value (including
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
          _buildDecisionRow(Theme.of(context)),
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

  Widget _buildDecisionRow(ThemeData theme) {
    final TextStyle base =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 8,
      children: <Widget>[
        _LabeledToggle(
          toggleKey: ValueKey<String>(acceptToggleKeyFor(rowIndex)),
          label: acceptLabel,
          labelStyle: base.copyWith(color: EditorialMonoclePalette.success),
          value: decision == true,
          onGlowColor: EditorialMonoclePalette.success,
          onChanged: (bool turnedOn) {
            // Tap on Accept: commit to true; tapping while already on
            // reverts to undecided (null) so R23 gating can re-engage.
            onDecisionChanged(turnedOn ? true : null);
          },
        ),
        _LabeledToggle(
          toggleKey: ValueKey<String>(rejectToggleKeyFor(rowIndex)),
          label: rejectLabel,
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

/// Small composite: `CtToggleSwitch` paired with a colored body label so the
/// Accept / Reject affordance is self-describing without an extra Row in the
/// parent (`_OvertureOfferRow` keeps its `build` within the per-`build`
/// non-comment line budget). Tapping anywhere in the row (toggle or label)
/// invokes [onChanged] with the negated [value] so the affordance behaves
/// like a single composite control. Not exported; private to the overture
/// overlay.
class _LabeledToggle extends StatelessWidget {
  const _LabeledToggle({
    required this.toggleKey,
    required this.label,
    required this.labelStyle,
    required this.value,
    required this.onGlowColor,
    required this.onChanged,
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
