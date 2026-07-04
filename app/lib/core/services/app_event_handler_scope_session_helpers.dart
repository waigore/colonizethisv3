part of 'app_event_handler_scope.dart';

int civilianWorkUpsertValidationPassCountForTests = 0;

void resetCivilianWorkUpsertValidationPassCountForTests() {
  civilianWorkUpsertValidationPassCountForTests = 0;
}

extension _SessionCommandHelpers on _AppEventHandlerScopeState {
  void _unlessTurnResolutionBlocksSession(
    String eventKind,
    void Function() apply,
  ) {
    if (ref.read(turnResolutionBlockingProvider)) {
      _logEvent.d('logic: blocked $eventKind during active turn resolution');
      return;
    }
    apply();
  }

  void _applyDebugCommand(DebugCommandResult result) {
    ref.read(debugCommandSessionHandlerProvider).apply(
          result,
          showSnackBar: _showSnackBar,
          logWarning: (message) => _logEvent.w(message),
        );
  }

  bool _rejectUiMutationIfObserving() => rejectUiMutationIfObserving(
        shell: ref.read(shellPlayerContextProvider),
        showSnack: _showSnackBar,
      );
}
