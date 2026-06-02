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

/// Treasury / stockpile summary strip for train dialogs.
class TrainDialogResourceBar extends StatelessWidget {
  const TrainDialogResourceBar({
    super.key,
    required this.lines,
    this.deficitHint,
  });

  final List<String> lines;
  final String? deficitHint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle lineStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.fg);
    final TextStyle deficitStyle = (theme.textTheme.bodySmall ??
            const TextStyle())
        .copyWith(color: EditorialMonoclePalette.danger);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: CtSpacing.l,
          runSpacing: 4,
          children: [for (final line in lines) Text(line, style: lineStyle)],
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
