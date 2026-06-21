import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../widgets/ct_brass_divider.dart';
import '../../../widgets/ct_gradients.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_radius.dart';
import '../../../widgets/ct_spacing.dart';

/// Locked train-dialog row opacity per `SPEC/ui/train-civilians-dialog.md` /
/// `SPEC/ui/train-military-dialog.md` and #2866 AC (0.4).
const double kTrainDialogLockedOpacity = 0.4;

/// Title letter-spacing aligned with [CtTopBar] / combat-mode choice dialog.
const double kTrainDialogTitleLetterSpacing = 0.05;

/// Dark editorial-monocle train-dialog header: accent title + dismiss control.
///
/// Implements `Refs #2866` S4/S5 — no Material [IconButton] / [Divider] chrome.
class TrainDialogHeader extends StatelessWidget {
  const TrainDialogHeader({
    super.key,
    required this.title,
    required this.onClose,
  });

  final String title;
  final VoidCallback onClose;

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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(title, style: titleStyle)),
        CtNinePatchButton(
          onPressed: onClose,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minHeight: 32,
          child: const Text('×'),
        ),
      ],
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
