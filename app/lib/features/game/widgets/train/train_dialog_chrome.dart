// Shared train-dialog chrome widgets and constants.
// SPEC/ui/components/train-dialog-chrome.md.
//
// De-parted wave-9 cluster (Refs #4117).

import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import '../../../../widgets/ct_spacing.dart';

export 'train_dialog_chrome_resource_bar.dart'
    show
        TrainDialogResourceBar,
        TrainDialogResourceBarBox,
        TrainDialogResourceChip,
        TrainDialogResourceEntry;
export 'train_dialog_chrome_unit_row_cost.dart'
    show TrainDialogInlineCost, TrainDialogLockedHint;
export 'train_dialog_chrome_unit_row_controls.dart'
    show TrainDialogStepper, TrainDialogUnitRowSurface;

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
