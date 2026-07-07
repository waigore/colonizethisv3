part of 'call_to_arms_dialogue_overlay.dart';

/// Per-call decision row for the call-to-arms overlay.
///
/// Mirrors the overture overlay's offer row (`SPEC/ui/overture-dialogue-overlay.md`
/// R22): the calling faction name renders in `--accent`, the war prompt in
/// `--muted`, and the Join / Refuse affordances are two mutually exclusive
/// `CtToggleSwitch` controls (issue #2867 R24). The Join toggle uses the
/// `--success` glow when active; the Refuse toggle uses the `--danger` glow.
///
/// The toggles are tristate-aware: tapping a currently-off toggle commits the
/// row to that decision and turns the other side off; tapping a currently-on
/// toggle reverts the row to the undecided (`null`) state, preserving the
/// #2867 R25 contract that Submit stays disabled until every row has a
/// non-null decision.
class _CallToArmsCallRow extends StatelessWidget {
  const _CallToArmsCallRow({
    required this.rowIndex,
    required this.factionName,
    required this.prompt,
    required this.joinLabel,
    required this.refuseLabel,
    required this.decision,
    required this.onDecisionChanged,
  });

  final int rowIndex;
  final String factionName;
  final String prompt;
  final String joinLabel;
  final String refuseLabel;

  /// Current tristate decision: `null` (undecided) / `true` (join) /
  /// `false` (refuse).
  final bool? decision;

  /// Reports the next tristate decision. Callers should `setState` the owning
  /// `_join[i]` slot to the passed value (including `null` when the user
  /// reverts a previously-committed toggle).
  final ValueChanged<bool?> onDecisionChanged;

  /// Stable test-grep key for the Join-side `CtToggleSwitch` in row N.
  static String joinToggleKeyFor(int rowIndex) =>
      'callToArmsJoinToggle_$rowIndex';

  /// Stable test-grep key for the Refuse-side `CtToggleSwitch` in row N.
  static String refuseToggleKeyFor(int rowIndex) =>
      'callToArmsRefuseToggle_$rowIndex';

  /// Stable test-grep key for the per-row prompt `Text.rich`.
  static const ValueKey<String> promptKey =
      ValueKey<String>('callToArmsPrompt');

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Per-call rows stack the prompt above an end-aligned Wrap of Join +
    // Refuse toggles so the row never relies on a horizontal
    // Row(Expanded(prompt) + controls) fitting at narrow viewports
    // (issue #2870 S8 / S10; SPEC/ui/call-to-arms-dialogue-overlay.md
    // § Layout / wireframe; SPEC/ui/mobile-adaptation.md § 7).
    return Padding(
      padding: const EdgeInsets.only(bottom: CtSpacing.ml),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildPrompt(theme),
          const SizedBox(height: CtSpacing.m),
          _buildDecisionRow(theme),
        ],
      ),
    );
  }

  /// Prompt line rendered as a single `Text.rich` so the calling faction
  /// name (the resolved defender display name) paints in
  /// `EditorialMonoclePalette.accent` while the surrounding war context
  /// stays `EditorialMonoclePalette.muted` (issue #2867 R24 "faction name
  /// in `--accent`"). Keeping it a single widget avoids duplicating the
  /// defender name in a separate header and preserves the localized
  /// `game_callToArms_prompt` sentence verbatim. When the faction name is
  /// not a substring of the resolved prompt (defensive — e.g. a future
  /// localization variant), the whole sentence falls back to `--muted`.
  Widget _buildPrompt(ThemeData theme) {
    final TextStyle base =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final TextStyle mutedStyle =
        base.copyWith(color: EditorialMonoclePalette.muted);
    final TextStyle accentStyle = base.copyWith(
      color: EditorialMonoclePalette.accent,
      fontWeight: FontWeight.w600,
    );
    final int idx = prompt.indexOf(factionName);
    if (idx < 0 || factionName.isEmpty) {
      return Text(prompt, key: promptKey, style: mutedStyle);
    }
    final String before = prompt.substring(0, idx);
    final String after = prompt.substring(idx + factionName.length);
    return Text.rich(
      TextSpan(
        style: mutedStyle,
        children: <InlineSpan>[
          if (before.isNotEmpty) TextSpan(text: before),
          TextSpan(text: factionName, style: accentStyle),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
      key: promptKey,
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
          toggleKey: ValueKey<String>(joinToggleKeyFor(rowIndex)),
          label: joinLabel,
          labelStyle: base.copyWith(color: EditorialMonoclePalette.success),
          value: decision == true,
          onGlowColor: EditorialMonoclePalette.success,
          onChanged: (bool turnedOn) {
            // Tap on Join: commit to true; tapping while already on reverts to
            // undecided (null) so R25 gating can re-engage.
            onDecisionChanged(turnedOn ? true : null);
          },
        ),
        _LabeledToggle(
          toggleKey: ValueKey<String>(refuseToggleKeyFor(rowIndex)),
          label: refuseLabel,
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
/// Join / Refuse affordance is self-describing without an extra parent Row.
/// Tapping anywhere in the row (toggle or label) invokes [onChanged] with the
/// negated [value] so the affordance behaves like a single composite control.
/// Mirrors the overture overlay's `_LabeledToggle` (issue #2867 R22 / R24);
/// kept file-local to avoid a cross-overlay refactor.
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
