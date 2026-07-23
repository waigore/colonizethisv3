part of 'train_dialog_chrome.dart';

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
