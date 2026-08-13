import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'dialogue_tristate_decision_row.dart';

/// Per-call decision row for the call-to-arms overlay.
///
/// Mirrors the overture overlay's offer row (`SPEC/ui/overture-dialogue-overlay.md`
/// R22): the calling faction name renders in `--accent`, the war prompt in
/// `--muted`, and Join / Refuse use [DialogueTristateDecisionRow] (issue #2867
/// R24 / #4018). First-order Join/Refuse Effect lines (Refs #4364) mirror
/// intervention choice Effects (`OVL50001` / #4267). Submit stays disabled
/// until every row has a non-null decision (R25).
class CallToArmsCallRow extends StatelessWidget {
  const CallToArmsCallRow({
    super.key,
    required this.rowIndex,
    required this.factionName,
    required this.prompt,
    required this.formalAllianceReason,
    required this.joinLabel,
    required this.refuseLabel,
    required this.joinEffect,
    required this.refuseEffect,
    required this.decision,
    required this.onDecisionChanged,
  });

  final int rowIndex;
  final String factionName;
  final String prompt;
  final String formalAllianceReason;
  final String joinLabel;
  final String refuseLabel;
  final String joinEffect;
  final String refuseEffect;

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

  /// Stable test-grep key for the optional formal-alliance reason line.
  static String formalAllianceReasonKeyFor(int rowIndex) =>
      'callToArmsFormalAllianceReason_$rowIndex';

  /// Stable test-grep key for the Join Effect line in row N.
  static String joinEffectKeyFor(int rowIndex) =>
      'callToArmsEffectJoin_$rowIndex';

  /// Stable test-grep key for the Refuse Effect line in row N.
  static String refuseEffectKeyFor(int rowIndex) =>
      'callToArmsEffectRefuse_$rowIndex';

  /// Stable test-grep key for the per-row prompt `Text.rich`.
  static const ValueKey<String> promptKey =
      ValueKey<String>('callToArmsPrompt');

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle effectStyle =
        (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12))
            .copyWith(color: EditorialMonoclePalette.muted);
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
          const SizedBox(height: CtSpacing.s),
          Text(
            formalAllianceReason,
            key: ValueKey<String>(formalAllianceReasonKeyFor(rowIndex)),
            style: effectStyle,
          ),
          const SizedBox(height: CtSpacing.m),
          DialogueTristateDecisionRow(
            positiveToggleKey: ValueKey<String>(joinToggleKeyFor(rowIndex)),
            negativeToggleKey: ValueKey<String>(refuseToggleKeyFor(rowIndex)),
            positiveLabel: joinLabel,
            negativeLabel: refuseLabel,
            decision: decision,
            onDecisionChanged: onDecisionChanged,
          ),
          const SizedBox(height: CtSpacing.s),
          Text(
            joinEffect,
            key: ValueKey<String>(joinEffectKeyFor(rowIndex)),
            style: effectStyle,
          ),
          const SizedBox(height: CtSpacing.xs),
          Text(
            refuseEffect,
            key: ValueKey<String>(refuseEffectKeyFor(rowIndex)),
            style: effectStyle,
          ),
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
}
