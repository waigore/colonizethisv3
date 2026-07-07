part of 'app_event_handler_scope.dart';

extension _SessionDiplomacyListeners on _AppEventHandlerScopeState {
  List<StreamSubscription<dynamic>> _diplomacySessionListeners(
    AppEventBus bus,
  ) {
    return [
      bus.on<AppendDiplomaticOrderRequestedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'AppendDiplomaticOrderRequestedEvent',
          () {
            if (_rejectUiMutationIfObserving()) return;
            final current = ref.read(currentOrdersProvider);
            ref
                .read(currentOrdersProvider.notifier)
                .replaceAll(
                  current.appendDiplomaticOrderForPlayer(e.playerId, e.order),
                );
          },
        );
      }),
      bus.on<RemoveDiplomaticOrderRequestedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'RemoveDiplomaticOrderRequestedEvent',
          () {
            if (_rejectUiMutationIfObserving()) return;
            final current = ref.read(currentOrdersProvider);
            ref
                .read(currentOrdersProvider.notifier)
                .replaceAll(
                  current.removeDiplomaticOrderForPlayer(
                    e.playerId,
                    type: e.type,
                    targetFactionId: e.targetFactionId,
                  ),
                );
          },
        );
      }),
      bus.on<BreakAllianceImmediatelyEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'BreakAllianceImmediatelyEvent',
          () {
            if (_rejectUiMutationIfObserving()) return;
            final current = ref.read(currentGameProvider);
            final result = applyBreakAllianceImmediately(
              currentGame: current,
              event: e,
            );
            final nextGame = result.game;
            if (nextGame == null) {
              _logEvent.w(result.message ?? 'Break Alliance rejected.');
              _showSnackBar(
                ShowSnackBarEvent(
                  message: result.message ?? 'Break Alliance rejected.',
                ),
              );
              return;
            }
            ref.read(currentGameProvider.notifier).setGame(nextGame);
            ref
                .read(gameServiceProvider)
                .saveGame(
                  ref
                      .read(observeSessionProvider.notifier)
                      .prepareGameForPersistence(nextGame),
                );
          },
        );
      }),
    ];
  }
}
