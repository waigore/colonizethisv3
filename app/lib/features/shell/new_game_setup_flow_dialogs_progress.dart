part of 'new_game_setup_flow.dart';

Future<_NewGameOutcome?> _showNewGameProgressDialog({
  required GlobalKey<NavigatorState> navigatorKey,
  required GameSetupConfig config,
  required GameService service,
}) async {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) {
    return null;
  }
  return showDialog<_NewGameOutcome>(
    context: ctx,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogCtx) =>
        _NewGameSetupProgressDialog(config: config, service: service),
  );
}

String _stepLabel(BuildContext context, int stepIndex) {
  final l10n = appL10n(context);
  switch (stepIndex) {
    case 0:
      return l10n.shell_newGameProgress_stepOldWorld;
    case 1:
      return l10n.shell_newGameProgress_stepNewWorld;
    case 2:
      return l10n.shell_newGameProgress_stepWarp;
    case 3:
      return l10n.shell_newGameProgress_stepBuildWorld;
    case 4:
      return l10n.shell_newGameProgress_stepSave;
    default:
      return l10n.shell_newGameProgress_title;
  }
}

/// Inert visual for the new-game progress dialog body (SHEL30001).
///
/// Renders the `CtDialogShell` chrome, the localised progress title, the
/// 48 px `--accent` spinner ring, and the current phase label for
/// [stepIndex] ∈ `0..4` per `SPEC/ui/game-initializing.md` § Dark-theme
/// visual contract (issue #2867 R32–R33).
///
/// This widget is intentionally synchronous and side-effect free so it can
/// be composed by Widgetbook stories and widget tests without driving the
/// `GameService` setup pipeline. The shell dialog
/// ([_NewGameSetupProgressDialog]) wraps this view in `PopScope(canPop:
/// false)` and drives [stepIndex] from the live `onProgress` callback.
class NewGameSetupProgressView extends StatelessWidget {
  const NewGameSetupProgressView({super.key, required this.stepIndex});

  /// Index of the current coarse setup phase (`0..4`); values outside that
  /// range fall back to the generic progress title per [_stepLabel].
  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    return CtDialogShell(
      maxWidth: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n.shell_newGameProgress_title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          CtLoadingIndicator(
            size: 48,
            strokeWidth: 2,
            color: EditorialMonoclePalette.accent,
            center: false,
          ),
          const SizedBox(height: 16),
          Text(_stepLabel(context, stepIndex), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _NewGameSetupProgressDialog extends StatefulWidget {
  const _NewGameSetupProgressDialog({
    required this.config,
    required this.service,
  });

  final GameSetupConfig config;
  final GameService service;

  @override
  State<_NewGameSetupProgressDialog> createState() =>
      _NewGameSetupProgressDialogState();
}

class _NewGameSetupProgressDialogState
    extends State<_NewGameSetupProgressDialog> {
  var _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    // Defer work by one extra frame so the modal route and nine-patch can paint
    // before map generation runs on the UI isolate (SPEC/ui/game-initializing.md).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_run());
      });
    });
  }

  Future<void> _run() async {
    try {
      final game = await widget.service.createNewGameAsync(
        config: widget.config,
        onProgress: (stepIndex, _) {
          if (mounted) {
            setState(() => _stepIndex = stepIndex);
          }
        },
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(_NewGameOutcomeSuccess(game));
    } catch (e, st) {
      _log.e('new game setup failed', error: e, stackTrace: st);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(_NewGameOutcomeFailure(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: NewGameSetupProgressView(stepIndex: _stepIndex),
    );
  }
}
