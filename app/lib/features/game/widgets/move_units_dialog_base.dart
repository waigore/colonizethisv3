// Shared scaffold + destination-row chrome for the in-game move dialogs.
//
// SPEC/ui/components/move-units-dialog-base.md.
// Consumed by SPEC/ui/move-army-dialog.md (`MoveArmyDialog`) and
// SPEC/ui/move-fleet-dialog.md (`MoveFleetDialog`): both render a
// `CtDialogShell` body of [title, CtSectionLabel-headed destination
// groups, trailing Cancel/Confirm Wrap] over the same 1 px/2 px
// `--border`/`--accent` radio-row outline contract (#2867 R1/R7).

import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_spacing.dart';
import 'chrome/ct_nine_patch_button.dart';

/// Title text style shared by the move dialogs — dark-theme `titleMedium`
/// in `--accent` with 0.05em letter spacing (#2867 R2/R5).
TextStyle moveDialogTitleTextStyle(ThemeData theme) {
  return (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16)).copyWith(
    color: EditorialMonoclePalette.accent,
    letterSpacing: 0.05 * 16,
    fontWeight: FontWeight.w600,
  );
}

/// Empty-state body style shared by the move dialogs (`--muted` body).
TextStyle moveDialogEmptyTextStyle(ThemeData theme) {
  return (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
    color: EditorialMonoclePalette.muted,
  );
}

/// Destination-row title style shared by the move dialogs. Selected rows
/// render at full `--fg`; idle rows at 90% `--fg` opacity (#2867 R7).
TextStyle moveDialogRowLabelStyle(ThemeData theme, {required bool selected}) {
  return (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
    color: selected
        ? EditorialMonoclePalette.fg
        : EditorialMonoclePalette.fg.withValues(alpha: 0.9),
  );
}

/// Abstract `State` base for the in-game move dialogs.
///
/// Subclasses supply the dialog title, destination body, and the
/// Confirm/Cancel actions; the base composes the shared `CtDialogShell`
/// scaffold (title row, empty-state fallback, and the trailing Wrap of
/// Cancel/Confirm `CtNinePatchButton`s) so the two dialogs cannot drift.
abstract class MoveUnitsDialogState<W extends StatefulWidget>
    extends State<W> {
  /// Localized dialog title (e.g. `Move army — Army <id>`).
  String get moveDialogTitle;

  /// Whether at least one destination is offered. When `false` the base
  /// renders [moveDialogEmptyText] in place of the destination body.
  bool get moveDialogHasDestinations;

  /// Localized empty-state copy shown when [moveDialogHasDestinations] is
  /// `false`.
  String get moveDialogEmptyText;

  /// Whether the Confirm action is enabled (a destination is selected).
  bool get moveDialogCanConfirm;

  /// Builds the destination body (the `CtSectionLabel`-headed groups).
  /// Only invoked when [moveDialogHasDestinations] is `true`.
  Widget buildMoveDialogDestinations(BuildContext context);

  /// Invoked when the user taps the enabled Confirm action.
  void onMoveDialogConfirm();

  /// Invoked when the user taps Cancel.
  void onMoveDialogCancel();

  /// Composes the shared `CtDialogShell` scaffold. Subclasses return this
  /// from their `build`.
  Widget buildMoveDialogScaffold(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final titleStyle = moveDialogTitleTextStyle(theme);
    final emptyStyle = moveDialogEmptyTextStyle(theme);

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(moveDialogTitle, style: titleStyle),
        const SizedBox(height: CtSpacing.ml),
        if (!moveDialogHasDestinations)
          Text(moveDialogEmptyText, style: emptyStyle)
        else
          buildMoveDialogDestinations(context),
        const SizedBox(height: CtSpacing.l),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: CtSpacing.m,
          runSpacing: CtSpacing.m,
          children: [
            CtNinePatchButton(
              onPressed: onMoveDialogCancel,
              child: Text(l10n.common_cancel),
            ),
            CtNinePatchButton(
              enabled: moveDialogCanConfirm,
              onPressed: moveDialogCanConfirm ? onMoveDialogConfirm : null,
              child: Text(l10n.common_confirm),
            ),
          ],
        ),
      ],
    );

    return CtDialogShell(child: body);
  }
}

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
