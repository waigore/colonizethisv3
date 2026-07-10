part of 'move_units_dialog_base.dart';

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
