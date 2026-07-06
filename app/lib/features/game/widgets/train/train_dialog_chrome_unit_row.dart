part of 'train_dialog_chrome.dart';

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
    // The whole `icon + number` segment is the tooltip trigger and touch
    // target: a `minWidth/minHeight` of `kMinTouchTargetSize` pads narrow
    // single-digit segments up to 44 dp while letting wider numeric labels
    // keep their natural footprint. With the enlarged 30 dp cost icon
    // (#3631 Phase 2) a single segment can be slightly wider than the narrow
    // cost-wrap column at the 320 dp minimum viewport, so the numeric label is
    // wrapped in a `Flexible` + `BoxFit.scaleDown` `FittedBox`: it renders at
    // its natural size when there is room and shrinks losslessly (no clipped
    // digits, no ellipsis) only when the column is too tight, keeping the cost
    // `Wrap` overflow-free.
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

/// `[−] count [+]` stepper control shared by all three train-dialog unit rows.
///
/// The `[−]` / `[+]` controls are [CtNinePatchButton]s; both disable while the
/// row is [isLocked] (and the `[−]` also when [canDecrement] is `false`, the
/// `[+]` when [canIncrement] is `false`). The `[+]` adopts the danger variant
/// when the row is affordable-blocked (`!isLocked && !canIncrement`) per
/// `SPEC/ui/components/train-dialog-chrome.md`.
class TrainDialogStepper extends StatelessWidget {
  const TrainDialogStepper({
    super.key,
    required this.count,
    required this.isLocked,
    required this.canIncrement,
    required this.canDecrement,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int count;
  final bool isLocked;
  final bool canIncrement;
  final bool canDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CtNinePatchButton(
          onPressed: isLocked || !canDecrement ? null : onDecrement,
          child: const Text('−'),
        ),
        CtGap.wm,
        SizedBox(
          width: 32,
          child: Text(
            count.toString(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        CtGap.wm,
        CtNinePatchButton(
          onPressed: isLocked || !canIncrement ? null : onIncrement,
          dangerVariant: !isLocked && !canIncrement,
          child: const Text('+'),
        ),
      ],
    );
  }
}

/// Gradient row surface for a single trainable unit type inside train dialogs.
class TrainDialogUnitRowSurface extends StatelessWidget {
  const TrainDialogUnitRowSurface({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: CtSpacing.s),
  });

  final Widget child;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: CtGradients.rowGradient,
          border: Border.all(
            color: EditorialMonoclePalette.accentDim,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CtSpacing.ml,
            vertical: CtSpacing.m,
          ),
          child: child,
        ),
      ),
    );
  }
}
