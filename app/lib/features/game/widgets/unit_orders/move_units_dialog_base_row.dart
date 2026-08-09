import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_spacing.dart';

/// Single destination row shared by the move dialogs.
///
/// Renders the canonical radio-row outline contract (#2867 R7): a 1 px
/// `--border` outline by default and a 2 px `--accent` outline with a
/// filled `--accent` dot when [selected]. The [content] occupies the
/// flexible middle slot and an optional [trailing] widget (e.g. a locate
/// action) sits at the end. No Material `Radio`/`RadioListTile` is used.
class MoveDialogDestinationRow extends StatelessWidget {
  const MoveDialogDestinationRow({
    super.key,
    required this.selected,
    required this.onTap,
    required this.semanticsLabel,
    required this.content,
    this.trailing,
  });

  final bool selected;
  final VoidCallback onTap;
  final String semanticsLabel;
  final Widget content;
  final Widget? trailing;

  static const double selectedBorderWidth = 2;
  static const double idleBorderWidth = 1;

  @override
  Widget build(BuildContext context) {
    final Color outline = selected
        ? EditorialMonoclePalette.accent
        : EditorialMonoclePalette.border;
    final double outlineWidth = selected
        ? selectedBorderWidth
        : idleBorderWidth;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Semantics(
        button: true,
        selected: selected,
        label: semanticsLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: outline, width: outlineWidth),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: CtSpacing.m,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MoveDialogRadioDot(selected: selected),
                const SizedBox(width: 10),
                Expanded(child: content),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Leading radio indicator shared by the move-dialog destination rows.
class MoveDialogRadioDot extends StatelessWidget {
  const MoveDialogRadioDot({super.key, required this.selected});

  final bool selected;

  static const double outerDiameter = 14;
  static const double innerDiameter = 6;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: outerDiameter,
      height: outerDiameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? EditorialMonoclePalette.accent
                    : EditorialMonoclePalette.border,
                width: 1,
              ),
            ),
          ),
          if (selected)
            Container(
              width: innerDiameter,
              height: innerDiameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EditorialMonoclePalette.accent,
              ),
            ),
        ],
      ),
    );
  }
}
