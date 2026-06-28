import 'package:flutter/material.dart';

import '../../../config/constants.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../widgets/ct_brass_divider.dart';
import '../../../widgets/ct_gap.dart';
import '../../../widgets/ct_gradients.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_radius.dart';
import '../../../widgets/ct_spacing.dart';

/// Locked train-dialog row opacity per `SPEC/ui/train-civilians-dialog.md` /
/// `SPEC/ui/train-military-dialog.md` / `SPEC/ui/train-naval-dialog.md` and the
/// canonical mockup `.unit-row.locked { opacity: 0.5 }` (#3568 chrome parity).
const double kTrainDialogLockedOpacity = 0.5;

/// Title letter-spacing aligned with [CtTopBar] / combat-mode choice dialog.
const double kTrainDialogTitleLetterSpacing = 0.05;

/// 🔒 (U+1F512) glyph prefixed to locked unit-type names per the canonical
/// train-dialog mockups (`.unit-row.locked` names), replacing a separate
/// lock-icon column. See [TrainDialogUnitNameLine].
const String kTrainDialogLockPrefix = '\u{1F512} ';

/// Rendered size (dp) of the cost-summary icons (commodity / treasury /
/// peasant) inside a [TrainDialogInlineCost].
///
/// Enlarged from 14 dp so the icons are legible at a glance (#3631 Phase 2);
/// the icon still nests inside the [kMinTouchTargetSize] (44 dp) tooltip/touch
/// region. See `SPEC/ui/components/train-dialog-chrome.md`.
const double kTrainDialogCostIconSize = 30;

/// Dark editorial-monocle train-dialog header: a centered accent title.
///
/// Per the canonical train-dialog mockups (`.dialog h3 { text-align: center }`,
/// title only — no `×` close button) the header renders the [title] centered
/// with no dismiss control; the dialog is dismissed via scrim tap / system back
/// (orders are still applied on close by the host `PopScope`). #3568 chrome
/// parity (supersedes the original `Refs #2866` left-aligned title + `×`).
class TrainDialogHeader extends StatelessWidget {
  const TrainDialogHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle titleStyle = (theme.textTheme.titleMedium ??
            const TextStyle())
        .copyWith(
          color: EditorialMonoclePalette.accent,
          letterSpacing: kTrainDialogTitleLetterSpacing,
          fontWeight: FontWeight.w600,
        );
    return Text(title, style: titleStyle, textAlign: TextAlign.center);
  }
}

/// Unit-type name line for a train-dialog row.
///
/// Locked rows prefix [name] with [kTrainDialogLockPrefix] (🔒) per the
/// canonical mockups instead of rendering a separate lock-icon column, so all
/// three train dialogs share one lock affordance. #3568 chrome parity.
class TrainDialogUnitNameLine extends StatelessWidget {
  const TrainDialogUnitNameLine({
    super.key,
    required this.name,
    required this.isLocked,
  });

  final String name;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      isLocked ? '$kTrainDialogLockPrefix$name' : name,
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

/// Full-width brass divider between train-dialog sections.
class TrainDialogSectionDivider extends StatelessWidget {
  const TrainDialogSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: CtSpacing.m),
      child: CtBrassDivider(),
    );
  }
}

/// A single label + value entry in a [TrainDialogResourceBar].
///
/// [label] renders muted; [value] renders monospace + bold (per the mockup
/// `.resource-bar .val`). Treasury values should be pre-formatted with the
/// `£` symbol + comma grouping via `formatTreasuryCurrency`.
class TrainDialogResourceEntry {
  const TrainDialogResourceEntry({required this.label, required this.value});

  final String label;
  final String value;
}

/// Boxed inset strip wrapping a train-dialog resource readout.
///
/// Mirrors the mockup `.resource-bar` (recessed `--bg-deep` background, 1 dp
/// `--border`) so both train dialogs share the same recessed treatment.
class TrainDialogResourceBarBox extends StatelessWidget {
  const TrainDialogResourceBarBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.bgDeep,
        border: Border.all(
          color: EditorialMonoclePalette.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CtSpacing.s),
        child: child,
      ),
    );
  }
}

/// Treasury / stockpile summary strip for train dialogs.
///
/// Renders [entries] inside a [TrainDialogResourceBarBox] with muted labels
/// and monospace bold values per the mockup. An optional [deficitHint]
/// renders below the box in the danger colour.
class TrainDialogResourceBar extends StatelessWidget {
  const TrainDialogResourceBar({
    super.key,
    required this.entries,
    this.deficitHint,
  });

  final List<TrainDialogResourceEntry> entries;
  final String? deficitHint;

  /// Monospace bold value style shared with [CtResourceCell] (`tabularFigures`
  /// + a cross-platform monospace fallback chain). Public so widget tests can
  /// assert the value styling.
  static TextStyle resourceValueStyle(BuildContext context) {
    final TextStyle base =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    return base.copyWith(
      color: EditorialMonoclePalette.fg,
      fontWeight: FontWeight.w700,
      fontFamilyFallback: const <String>['SF Mono', 'Menlo', 'monospace'],
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle labelStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.muted);
    final TextStyle valueStyle = resourceValueStyle(context);
    final TextStyle deficitStyle = (theme.textTheme.bodySmall ??
            const TextStyle())
        .copyWith(color: EditorialMonoclePalette.danger);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrainDialogResourceBarBox(
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            alignment: WrapAlignment.spaceAround,
            children: [
              for (final entry in entries)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: entry.label, style: labelStyle),
                      const TextSpan(text: ' '),
                      TextSpan(text: entry.value, style: valueStyle),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (deficitHint != null) ...[
          const SizedBox(height: 4),
          Text(deficitHint!, style: deficitStyle),
        ],
      ],
    );
  }
}

/// Compact resource summary chip on the train-dialog resource bar.
class TrainDialogResourceChip extends StatelessWidget {
  const TrainDialogResourceChip({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: CtGradients.rowGradient,
        border: Border.all(
          color: EditorialMonoclePalette.accentDim,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(CtRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CtSpacing.s,
          vertical: 4,
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: EditorialMonoclePalette.fg),
          child: child,
        ),
      ),
    );
  }
}

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
