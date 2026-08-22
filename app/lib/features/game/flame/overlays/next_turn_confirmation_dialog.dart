import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../config/ui_screen_ids.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/ct_toggle_switch.dart';
import 'package:colonizethis_logic/civilian_intel_api.dart'
    show CivilianMissingWorkOrderEntry;

import '../../turn_resolution/staged_decree_review.dart';
import 'next_turn_confirmation_idle_row.dart';
import 'staged_decree_review_section.dart';

/// Outcome of [showNextTurnConfirmationDialog].
class NextTurnConfirmationResult {
  const NextTurnConfirmationResult({
    required this.confirmed,
    this.persistDontShowAgain = false,
  });

  final bool confirmed;
  final bool persistDontShowAgain;
}

/// Shows the "End turn?" confirmation dialog (DLG60001).
///
/// SPEC: SPEC/ui/next-turn-confirmation.md — title in `--accent`, body in
/// `--fg`, both actions use `CtNinePatchButton` brass styling. No Material
/// chrome (`AlertDialog`, `TextButton`).
Future<NextTurnConfirmationResult?> showNextTurnConfirmationDialog(
  BuildContext context, {
  required int currentTurn,
  List<CivilianMissingWorkOrderEntry> civiliansMissingWork = const [],
  StagedDecreeReview stagedReview = StagedDecreeReview.empty,
  void Function(CivilianMissingWorkOrderEntry entry)? onGoToCivilian,
  void Function(StagedDecreeFamily family)? onGoToStagedFamily,
}) async {
  return showDialog<NextTurnConfirmationResult>(
    context: context,
    builder: (BuildContext ctx) => NextTurnConfirmationDialog(
      currentTurn: currentTurn,
      civiliansMissingWork: civiliansMissingWork,
      stagedReview: stagedReview,
      onGoToCivilian: onGoToCivilian,
      onGoToStagedFamily: onGoToStagedFamily,
    ),
  );
}

/// Static dialog body for the next-turn confirmation prompt (DLG60001).
///
/// Extracted so the dialog can be exercised in widget tests and Widgetbook
/// stories without driving the top-bar Next Turn flow.
class NextTurnConfirmationDialog extends StatefulWidget {
  const NextTurnConfirmationDialog({
    super.key,
    required this.currentTurn,
    this.civiliansMissingWork = const [],
    this.stagedReview = StagedDecreeReview.empty,
    this.onGoToCivilian,
    this.onGoToStagedFamily,
  });

  static const screenId = UiScreenIds.nextTurnConfirmation;

  final int currentTurn;
  final List<CivilianMissingWorkOrderEntry> civiliansMissingWork;
  final StagedDecreeReview stagedReview;
  final void Function(CivilianMissingWorkOrderEntry entry)? onGoToCivilian;
  final void Function(StagedDecreeFamily family)? onGoToStagedFamily;

  @override
  State<NextTurnConfirmationDialog> createState() =>
      _NextTurnConfirmationDialogState();
}

class _NextTurnConfirmationDialogState
    extends State<NextTurnConfirmationDialog> {
  bool _dontShowAgain = false;

  bool get _showWarning => widget.civiliansMissingWork.isNotEmpty;

  bool get _showStaged => !widget.stagedReview.isEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10n(context);
    final titleStyle = (theme.textTheme.titleMedium ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.accent);
    final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.fg);
    final mutedStyle = (theme.textTheme.bodySmall ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.muted);
    return CtDialogShell(
      maxHeight: (_showWarning || _showStaged) ? 520 : 600,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.game_nextTurnConfirm_title, style: titleStyle),
          const SizedBox(height: CtSpacing.m),
          Text(
            l10n.game_nextTurnConfirm_body(widget.currentTurn),
            style: bodyStyle,
          ),
          StagedDecreeReviewSection(
            review: widget.stagedReview,
            bodyStyle: bodyStyle,
            mutedStyle: mutedStyle,
            onGoToFamily: widget.onGoToStagedFamily == null
                ? null
                : (family) {
                    widget.onGoToStagedFamily!(family);
                    Navigator.of(
                      context,
                    ).pop(const NextTurnConfirmationResult(confirmed: false));
                  },
          ),
          if (_showWarning) ...[
            const SizedBox(height: CtSpacing.l),
            Text(
              l10n.game_nextTurnConfirm_idleCiviliansSection,
              style: bodyStyle,
            ),
            const SizedBox(height: CtSpacing.m),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final entry in widget.civiliansMissingWork)
                      NextTurnIdleCivilianWarningRow(
                        key: ValueKey('idle-civilian-warning-${entry.unitId}'),
                        entry: entry,
                        bodyStyle: bodyStyle,
                        mutedStyle: mutedStyle,
                        locateTooltip: l10n.common_locate,
                        noWorkOrderLabel: l10n.game_nextTurnConfirm_noWorkOrder,
                        onGoTo: widget.onGoToCivilian == null
                            ? null
                            : () {
                                widget.onGoToCivilian!(entry);
                                Navigator.of(context).pop(
                                  const NextTurnConfirmationResult(
                                    confirmed: false,
                                  ),
                                );
                              },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: CtSpacing.m),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CtToggleSwitch(
                  key: const ValueKey('nextTurnConfirm.dontShowAgain'),
                  value: _dontShowAgain,
                  onChanged: (value) => setState(() => _dontShowAgain = value),
                ),
                const SizedBox(width: CtSpacing.m),
                Expanded(
                  child: Text(
                    l10n.game_nextTurnConfirm_dontShowAgain,
                    style: bodyStyle,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: CtSpacing.l),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CtNinePatchButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop(const NextTurnConfirmationResult(confirmed: false)),
                child: Text(l10n.common_no),
              ),
              const SizedBox(width: CtSpacing.m),
              CtNinePatchButton(
                onPressed: () => Navigator.of(context).pop(
                  NextTurnConfirmationResult(
                    confirmed: true,
                    persistDontShowAgain: _dontShowAgain,
                  ),
                ),
                child: Text(l10n.common_yes),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
