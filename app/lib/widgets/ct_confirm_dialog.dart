import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';
import 'ct_dialog_shell.dart';
import 'ct_nine_patch_button.dart';
import 'ct_spacing.dart';

/// Generic dark editorial-monocle confirmation dialog.
///
/// Renders a [CtDialogShell]-framed prompt with a title, a body message, and
/// two `CtNinePatchButton` actions (cancel + confirm) — the canonical
/// editorial-monocle replacement for Material `AlertDialog` + `TextButton`
/// pairs (per `SPEC/ui/pixel-art-ui-catalog.md` § Material design ban — Ct-\*
/// counterparts table).
///
/// Returns `true` via [Navigator.pop] when the confirm button is tapped,
/// `false` when the cancel button is tapped, and `null` when the route is
/// dismissed by tapping the barrier (callers should treat `null` as
/// cancellation; [showCtConfirmDialog] does this for you).
///
/// Visual contract (mirrors `ExitConfirmDialog`):
///   * Title in `--accent` (display slot, bold).
///   * Body in `--fg`.
///   * Both actions are `CtNinePatchButton`; the destructive intent is
///     conveyed only by the caller-chosen [confirmLabel] (e.g. `"Confirm"`,
///     `"OK"`). Use a dedicated destructive-flow dialog (`dangerVariant`)
///     when the confirm side is genuinely destructive — generic confirm
///     prompts driven by [ConfirmDialogEvent](_) keep both buttons in the
///     standard brass style so the visual language matches the simple
///     yes/no semantics of the bus contract.
///
/// SPEC: `SPEC/program/app-event-bus.md` § `ConfirmDialogEvent` — bool
/// result; `SPEC/ui/pixel-art-ui-catalog.md` § Material design ban.
class CtConfirmDialog extends StatelessWidget {
  const CtConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = defaultConfirmLabel,
    this.cancelLabel = defaultCancelLabel,
  });

  /// Title text rendered at the top of the dialog body in `--accent`.
  final String title;

  /// Body message rendered under the title in `--fg`.
  final String message;

  /// Label for the confirm (right) action. Defaults to [defaultConfirmLabel]
  /// so the bus-level `ConfirmDialogEvent` default surfaces unchanged.
  final String confirmLabel;

  /// Label for the cancel (left) action. Defaults to [defaultCancelLabel] so
  /// the bus-level `ConfirmDialogEvent` default surfaces unchanged.
  final String cancelLabel;

  /// Default confirm-button label — matches the `ConfirmDialogEvent`
  /// constructor default in `packages/colonizethis_models/lib/src/app_events.dart`.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String defaultConfirmLabel = 'OK';

  /// Default cancel-button label — matches the `ConfirmDialogEvent`
  /// constructor default in `packages/colonizethis_models/lib/src/app_events.dart`.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String defaultCancelLabel = 'Cancel';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: EditorialMonoclePalette.accent,
      fontWeight: FontWeight.w700,
    );
    final TextStyle? bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: EditorialMonoclePalette.fg,
    );

    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: titleStyle),
          const SizedBox(height: CtSpacing.m),
          Text(message, style: bodyStyle),
          const SizedBox(height: CtSpacing.l),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              CtNinePatchButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelLabel),
              ),
              const SizedBox(width: CtSpacing.m),
              CtNinePatchButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Show a [CtConfirmDialog] anchored on the given [context]'s navigator with
/// the canonical editorial-monocle dialog scrim
/// ([EditorialMonoclePalette.dialogScrim]).
///
/// Resolves to `true` when the player confirms, `false` when they cancel or
/// dismiss the barrier (mirroring the `ConfirmDialogEvent` bool contract in
/// `SPEC/program/app-event-bus.md`).
///
/// [useRootNavigator] defaults to `true` so callers driven by
/// `AppEventHandler` reach across modal bottom sheets / inner navigators —
/// matching the existing wiring in
/// `app/lib/core/services/app_event_handler.dart`.
Future<bool> showCtConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = CtConfirmDialog.defaultConfirmLabel,
  String cancelLabel = CtConfirmDialog.defaultCancelLabel,
  bool useRootNavigator = true,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: useRootNavigator,
    barrierColor: EditorialMonoclePalette.dialogScrim,
    builder: (BuildContext ctx) => CtConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
  return result ?? false;
}
