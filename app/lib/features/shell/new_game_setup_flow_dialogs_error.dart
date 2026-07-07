part of 'new_game_setup_flow.dart';

Future<bool> _showNewGameErrorDialog({
  required GlobalKey<NavigatorState> navigatorKey,
  required Object error,
}) async {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) {
    return false;
  }
  final l10n = appL10n(ctx);
  final retry = await showDialog<bool>(
    context: ctx,
    useRootNavigator: true,
    builder: (ctx) => CtDialogShell(
      child: NewGameErrorCard(
        title: l10n.shell_newGameError_title,
        message: error.toString(),
        closeLabel: l10n.common_close,
        retryLabel: l10n.shell_newGameError_retry,
        onClose: () => Navigator.of(ctx).pop(false),
        onRetry: () => Navigator.of(ctx).pop(true),
      ),
    ),
  );
  return retry ?? false;
}

/// `--danger`-bordered error card painted inside the [CtDialogShell] when
/// new-game setup fails.
///
/// SPEC: `SPEC/ui/game-initializing.md` § Failure and retry; dark-theme
/// visual contract from issue #2867 R34 (1 px `--danger` border on all four
/// sides, `Retry` primary + `Close` secondary `CtNinePatchButton` actions).
///
/// The card is decoupled from any `Navigator` so Widgetbook and widget tests
/// can compose it directly without driving a `showDialog` flow. The shell
/// flow wires [onClose] / [onRetry] to `Navigator.pop(false / true)` so the
/// existing `Future<bool>` retry contract in [_showNewGameErrorDialog]
/// remains unchanged.
class NewGameErrorCard extends StatelessWidget {
  const NewGameErrorCard({
    super.key,
    required this.title,
    required this.message,
    required this.closeLabel,
    required this.retryLabel,
    this.onClose,
    this.onRetry,
  });

  /// Short error-card title (e.g. "Could not create game").
  final String title;

  /// Exception body (typically `error.toString()`).
  final String message;

  /// Label for the secondary (`Close`) `CtNinePatchButton`.
  final String closeLabel;

  /// Label for the primary (`Retry`) `CtNinePatchButton`.
  final String retryLabel;

  /// Invoked when the user taps the `Close` button. Optional so the card can
  /// be previewed in Widgetbook without wiring a callback.
  final VoidCallback? onClose;

  /// Invoked when the user taps the `Retry` button. Optional so the card can
  /// be previewed in Widgetbook without wiring a callback.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: EditorialMonoclePalette.danger, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CtSpacing.ml),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(message),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CtNinePatchButton(
                  onPressed: onClose,
                  child: Text(closeLabel),
                ),
                const SizedBox(width: 8),
                CtNinePatchButton(
                  onPressed: onRetry,
                  child: Text(retryLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
