part of 'app_event_handler_scope.dart';

extension _SessionNavalListeners on _AppEventHandlerScopeState {
  List<StreamSubscription<dynamic>> _navalSessionListeners(AppEventBus bus) {
    return [
      bus.on<NavalFleetsUpdatedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession('NavalFleetsUpdatedEvent', () {
          ref.read(currentGameProvider.notifier).setGame(e.game);
        });
      }),
      bus.on<NavalSplitFleetRequestedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'NavalSplitFleetRequestedEvent',
          () {
            if (_rejectUiMutationIfObserving()) return;
            final g = ref.read(currentGameProvider);
            if (g == null) return;
            final newGame = applyNavalSplitFleet(
              game: g,
              humanPlayerId: e.humanPlayerId,
              originalFleetId: e.originalFleetId,
              shipInstanceIdsToNewFleet: e.shipInstanceIdsToNewFleet,
            );
            bus.emit(NavalFleetsUpdatedEvent(game: newGame));
          },
        );
      }),
      bus.on<NavalTransferShipsRequestedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'NavalTransferShipsRequestedEvent',
          () {
            if (_rejectUiMutationIfObserving()) return;
            final g = ref.read(currentGameProvider);
            if (g == null) return;
            final newGame = applyNavalTransferShipsBetweenFleets(
              game: g,
              humanPlayerId: e.humanPlayerId,
              sourceFleetId: e.sourceFleetId,
              targetFleetId: e.targetFleetId,
              shipInstanceIdsToTransfer: e.shipInstanceIdsToTransfer,
            );
            bus.emit(NavalFleetsUpdatedEvent(game: newGame));
          },
        );
      }),
      bus.on<NavalMoveFleetRequestedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'NavalMoveFleetRequestedEvent',
          () {
            if (_rejectUiMutationIfObserving()) return;
            final o = ref.read(currentOrdersProvider);
            ref
                .read(currentOrdersProvider.notifier)
                .replaceAll(
                  applyNavalMoveOrderForPlayer(o, e.humanPlayerId, e.moveOrder),
                );
          },
        );
      }),
      bus.on<TrainNavalBuildOrdersCommittedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'TrainNavalBuildOrdersCommittedEvent',
          () {
            if (_rejectUiMutationIfObserving()) return;
            final g = ref.read(currentGameProvider);
            if (g == null) return;
            final pid = resolveShellPanelPlayerId(
              ref.read(shellPlayerContextProvider),
              g,
            );
            final o = ref.read(currentOrdersProvider);
            ref
                .read(currentOrdersProvider.notifier)
                .replaceAll(
                  _mergeTrainNavalOrdersForPlayer(
                    current: o,
                    game: g,
                    humanPlayerId: pid,
                    newFromDialog: e.orders,
                  ),
                );
          },
        );
      }),
    ];
  }
}
