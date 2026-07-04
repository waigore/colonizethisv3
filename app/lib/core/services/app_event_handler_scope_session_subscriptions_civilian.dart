part of 'app_event_handler_scope.dart';

extension _SessionCivilianWorkListeners on _AppEventHandlerScopeState {
  List<StreamSubscription<dynamic>> _civilianWorkSessionListeners(
    AppEventBus bus,
  ) {
    return [
      bus.on<RemovePendingWorkOrderRequestedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'RemovePendingWorkOrderRequestedEvent',
          () {
            if (_rejectUiMutationIfObserving()) return;
            final current = ref.read(currentOrdersProvider);
            final updated = removePendingWorkOrderAt(
              current,
              e.playerId,
              e.index,
            );
            ref.read(currentOrdersProvider.notifier).replaceAll(updated);
          },
        );
      }),
      bus.on<UpsertPendingCivilianWorkOrderRequestedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'UpsertPendingCivilianWorkOrderRequestedEvent',
          () {
            if (_rejectUiMutationIfObserving()) return;
            final current = ref.read(currentOrdersProvider);
            final playerId = e.playerId;
            final workOrder = e.workOrder;
            final nextWorkOrders = List<WorkOrder>.from(
              current.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[],
            )..removeWhere((o) => o.unitId == workOrder.unitId);
            nextWorkOrders.add(workOrder);
            final nextMoveOrders = List<MoveOrder>.from(
              current.moveOrdersByPlayerId[playerId] ?? const <MoveOrder>[],
            )..removeWhere((o) => o.unitId == workOrder.unitId);
            final next = current.copyWith(
              moveOrdersByPlayerId: {
                ...current.moveOrdersByPlayerId,
                playerId: nextMoveOrders,
              },
              workOrdersByPlayerId: {
                ...current.workOrdersByPlayerId,
                playerId: nextWorkOrders,
              },
            );

            final game = ref.read(currentGameProvider);
            if (game != null) {
              final topo =
                  ref
                      .read(gameServiceProvider)
                      .getMapData(game.id)
                      ?.combinedTopology ??
                  const MapTopology();
              final tileMaps = ref
                  .read(gameServiceProvider)
                  .getMapData(game.id)
                  ?.tileMapByRegion;
              final engine = OrderEngine(
                initialOrders: next,
                projector: projectOrderEffects,
              );
              civilianWorkUpsertValidationPassCountForTests += 1;
              final results = engine.validatePlayerOrdersWithContext(
                game,
                topo,
                playerId,
                tileMapByRegion: tileMaps,
              );
              if (!results.every((r) => r.isAccepted)) {
                _logEvent.e(
                  'ui: civilian work upsert rejected: draft failed order validation',
                );
                var message = 'Could not assign work order (orders invalid).';
                for (final r in results) {
                  if (!r.isAccepted &&
                      (r.reason?.isNotEmpty ?? false) &&
                      r.reason != 'Previous invalid') {
                    message = 'Could not assign work: ${r.reason}';
                    break;
                  }
                }
                _showSnackBar(ShowSnackBarEvent(message: message));
                assert(
                  results.every((r) => r.isAccepted),
                  'UpsertPendingCivilianWorkOrderRequestedEvent produced an invalid draft',
                );
                return;
              }
            }

            ref.read(currentOrdersProvider.notifier).replaceAll(next);
          },
        );
      }),
      bus.on<CancelInProgressCivilianWorkRequestedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'CancelInProgressCivilianWorkRequestedEvent',
          () {
            if (_rejectUiMutationIfObserving()) return;
            final game = ref.read(currentGameProvider);
            if (game == null) return;
            final newGame = clearUnitCurrentWork(game, e.unitId);
            ref.read(currentGameProvider.notifier).setGame(newGame);
            ref
                .read(gameServiceProvider)
                .saveGame(
                  ref
                      .read(observeSessionProvider.notifier)
                      .prepareGameForPersistence(newGame),
                );
          },
        );
      }),
      bus.on<TrainCivilianBuildOrdersCommittedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'TrainCivilianBuildOrdersCommittedEvent',
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
                  _mergeTrainCivilianOrdersForPlayer(
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
