import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../config/ui_screen_ids.dart';
import '../../../../widgets/civilian_unit_type_icon.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_icon_action.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/ct_toggle_switch.dart';
import '../../turn_resolution/civilians_missing_work_orders.dart';

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
  void Function(CivilianMissingWorkOrderEntry entry)? onGoToCivilian,
}) async {
  return showDialog<NextTurnConfirmationResult>(
    context: context,
    builder: (BuildContext ctx) => NextTurnConfirmationDialog(
      currentTurn: currentTurn,
      civiliansMissingWork: civiliansMissingWork,
      onGoToCivilian: onGoToCivilian,
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
    this.onGoToCivilian,
  });

  static const screenId = UiScreenIds.nextTurnConfirmation;

  final int currentTurn;
  final List<CivilianMissingWorkOrderEntry> civiliansMissingWork;
  final void Function(CivilianMissingWorkOrderEntry entry)? onGoToCivilian;

  @override
  State<NextTurnConfirmationDialog> createState() =>
      _NextTurnConfirmationDialogState();
}

class _NextTurnConfirmationDialogState extends State<NextTurnConfirmationDialog> {
  bool _dontShowAgain = false;

  bool get _showWarning => widget.civiliansMissingWork.isNotEmpty;

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
      maxHeight: _showWarning ? 520 : 600,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.game_nextTurnConfirm_title, style: titleStyle),
          const SizedBox(height: CtSpacing.m),
          Text(l10n.game_nextTurnConfirm_body(widget.currentTurn), style: bodyStyle),
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
                      _IdleCivilianWarningRow(
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
                onPressed: () => Navigator.of(context).pop(
                  const NextTurnConfirmationResult(confirmed: false),
                ),
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

class _IdleCivilianWarningRow extends StatelessWidget {
  const _IdleCivilianWarningRow({
    super.key,
    required this.entry,
    required this.bodyStyle,
    required this.mutedStyle,
    required this.locateTooltip,
    required this.noWorkOrderLabel,
    required this.onGoTo,
  });

  final CivilianMissingWorkOrderEntry entry;
  final TextStyle bodyStyle;
  final TextStyle mutedStyle;
  final String locateTooltip;
  final String noWorkOrderLabel;
  final VoidCallback? onGoTo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CtSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CivilianUnitTypeIcon(unitType: entry.type),
          const SizedBox(width: CtSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.type, style: bodyStyle, overflow: TextOverflow.ellipsis),
                Text(
                  entry.locationLabel,
                  style: mutedStyle,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  noWorkOrderLabel,
                  style: mutedStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          CtIconAction(
            key: ValueKey('idle-civilian-locate-${entry.unitId}'),
            icon: Icons.my_location,
            tooltip: locateTooltip,
            onPressed: onGoTo,
          ),
        ],
      ),
    );
  }
}
