import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_loading_indicator.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'new_game_setup_flow_outcome.dart';

final newGameSetupProgressLog = packageLogger('shell');

Future<NewGameSetupOutcome?> showNewGameSetupProgressDialog({
  required GlobalKey<NavigatorState> navigatorKey,
  required GameSetupConfig config,
  required GameService service,
}) async {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) {
    return null;
  }
  return showDialog<NewGameSetupOutcome>(
    context: ctx,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogCtx) =>
        NewGameSetupProgressDialog(config: config, service: service),
  );
}

String newGameSetupStepLabel(BuildContext context, int stepIndex) {
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
/// ([NewGameSetupProgressDialog]) wraps this view in `PopScope(canPop:
/// false)` and drives [stepIndex] from the live `onProgress` callback.
class NewGameSetupProgressView extends StatelessWidget {
  const NewGameSetupProgressView({super.key, required this.stepIndex});

  /// Index of the current coarse setup phase (`0..4`); values outside that
  /// range fall back to the generic progress title per [newGameSetupStepLabel].
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
          Text(newGameSetupStepLabel(context, stepIndex), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class NewGameSetupProgressDialog extends StatefulWidget {
  const NewGameSetupProgressDialog({
    super.key,
    required this.config,
    required this.service,
  });

  final GameSetupConfig config;
  final GameService service;

  @override
  State<NewGameSetupProgressDialog> createState() =>
      _NewGameSetupProgressDialogState();
}

class _NewGameSetupProgressDialogState extends State<NewGameSetupProgressDialog> {
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
      Navigator.of(context).pop(NewGameSetupOutcomeSuccess(game));
    } catch (e, st) {
      newGameSetupProgressLog.e('new game setup failed', error: e, stackTrace: st);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(NewGameSetupOutcomeFailure(e));
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
