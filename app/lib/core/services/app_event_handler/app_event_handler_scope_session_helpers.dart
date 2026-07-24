import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_app/providers/turn_resolution_blocking_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/game/widgets/shell/shell_player_context.dart';
import '../debug/debug_command_session_handler.dart';
import 'package:colonizethis_app_debug/colonizethis_app_debug.dart' show DebugCommandResult;
import '../observe/observe_mode_session_handler.dart' as observe_session;
import 'app_event_handler_scope.dart';

final appEventHandlerScopeLog = packageLogger('event');

int civilianWorkUpsertValidationPassCountForTests = 0;

void resetCivilianWorkUpsertValidationPassCountForTests() {
  civilianWorkUpsertValidationPassCountForTests = 0;
}

mixin AppEventHandlerScopeSessionHelpers on ConsumerState<AppEventHandlerScope> {
  void showSnackBarForEvent(ShowSnackBarEvent event) {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(ctx);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(event.message),
        action: event.actionLabel != null && event.action != null
            ? SnackBarAction(
                label: event.actionLabel!,
                onPressed: event.action!,
              )
            : null,
      ),
    );
  }

  void unlessTurnResolutionBlocksSession(
    String eventKind,
    void Function() apply,
  ) {
    if (ref.read(turnResolutionBlockingProvider)) {
      appEventHandlerScopeLog.d(
        'logic: blocked $eventKind during active turn resolution',
      );
      return;
    }
    apply();
  }

  void applyDebugCommand(DebugCommandResult result) {
    ref.read(debugCommandSessionHandlerProvider).apply(
      result,
      showSnackBar: showSnackBarForEvent,
      logWarning: (message) => appEventHandlerScopeLog.w(message),
    );
  }

  bool rejectUiMutationIfObserving() =>
      observe_session.rejectUiMutationIfObserving(
        shell: ref.read(shellPlayerContextProvider),
        showSnack: showSnackBarForEvent,
      );
}
