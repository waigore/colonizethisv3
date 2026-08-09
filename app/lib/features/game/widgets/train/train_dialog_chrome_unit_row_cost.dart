import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../config/constants.dart';

/// Inline `icon + number` cost segment in a train-dialog unit-row cost
/// summary (treasury / peasant / commodity requirement).
///
/// The [icon] is wrapped in a [Tooltip] (`TooltipTriggerMode.tap` — hover on
/// desktop, tap on mobile) showing [tooltipMessage] so the icon's meaning is
/// discoverable without an adjacent name label. The tooltip-trigger region is
/// constrained to at least [kMinTouchTargetSize] (44 dp) in both dimensions so
/// it is reachable on narrow mobile viewports (`SPEC/ui/mobile-adaptation.md`
/// § 1). The numeric [label] renders in [EditorialMonoclePalette.danger] when
/// [isInsufficient] is `true` (remaining stockpile cannot cover one more unit).
///
/// Shared by the military and naval train dialogs; see
/// `SPEC/ui/components/train-dialog-chrome.md` and
/// `SPEC/ui/components/resource-icon-tooltip.md`.
class TrainDialogInlineCost extends StatelessWidget {
  const TrainDialogInlineCost({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltipMessage,
    this.isInsufficient = false,
  });

  final Widget icon;
  final String label;

  /// Resource name (+ category for commodities) shown on hover/tap.
  final String tooltipMessage;

  /// When `true`, [label] renders in [EditorialMonoclePalette.danger] to flag
  /// that the remaining stockpile cannot cover one more of this unit.
  final bool isInsufficient;

  @override
  Widget build(BuildContext context) {
    final TextStyle? baseStyle = Theme.of(context).textTheme.bodySmall;
    final TextStyle? style = isInsufficient
        ? (baseStyle ?? const TextStyle()).copyWith(
            color: EditorialMonoclePalette.danger,
          )
        : baseStyle;
    return Tooltip(
      message: tooltipMessage,
      triggerMode: TooltipTriggerMode.tap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: kMinTouchTargetSize,
          minHeight: kMinTouchTargetSize,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 3),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(label, style: style),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tech-lock requirement hint shown under a locked train-dialog unit row's
/// cost line.
///
/// Renders nothing (`SizedBox.shrink()`) when the row is unlocked; when
/// [isLocked] is `true` it renders [techRequiredLabel] in
/// [EditorialMonoclePalette.muted] with a 2 dp gap above (matching the legacy
/// per-dialog `_buildLockedHint`). Shared by all three train dialogs.
class TrainDialogLockedHint extends StatelessWidget {
  const TrainDialogLockedHint({
    super.key,
    required this.isLocked,
    required this.techRequiredLabel,
  });

  final bool isLocked;
  final String techRequiredLabel;

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        techRequiredLabel,
        style: theme.textTheme.bodySmall?.copyWith(
          color: EditorialMonoclePalette.muted,
        ),
      ),
    );
  }
}
