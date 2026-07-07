part of 'app_event_handler_scope.dart';

extension _SessionArmyListeners on _AppEventHandlerScopeState {
  List<StreamSubscription<dynamic>> _armySessionListeners(AppEventBus bus) {
    return [
      bus.on<LandArmiesUpdatedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession('LandArmiesUpdatedEvent', () {
          ref.read(currentGameProvider.notifier).setGame(e.game);
        });
      }),
      bus.on<ArmyCombineRequestedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'ArmyCombineRequestedEvent',
          () {
            if (_rejectUiMutationIfObserving()) return;
            final g = ref.read(currentGameProvider);
            if (g == null) return;
            final next = applyArmyCombine(
              game: g,
              playerId: e.humanPlayerId,
              armyIds: e.armyIds,
            );
            bus.emit(LandArmiesUpdatedEvent(game: next));
          },
        );
      }),
      bus.on<ArmySplitRequestedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession('ArmySplitRequestedEvent', () {
          if (_rejectUiMutationIfObserving()) return;
          final g = ref.read(currentGameProvider);
          if (g == null) return;
          final next = applyArmySplit(
            game: g,
            playerId: e.humanPlayerId,
            sourceArmyId: e.sourceArmyId,
            unitIdsToMove: e.unitIdsToMove,
          );
          bus.emit(LandArmiesUpdatedEvent(game: next));
        });
      }),
      bus.on<ArmyMoveRequestedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession('ArmyMoveRequestedEvent', () {
          if (_rejectUiMutationIfObserving()) return;
          final g = ref.read(currentGameProvider);
          if (g == null) return;
          final topo =
              ref
                  .read(gameServiceProvider)
                  .getMapData(g.id)
                  ?.combinedTopology ??
              const MapTopology();
          final o = ref.read(currentOrdersProvider);
          var next = o;
          final warTarget = e.declareWarTargetFactionId;
          if (warTarget != null) {
            final diploList =
                next.diplomaticOrdersByPlayerId[e.humanPlayerId] ?? const [];
            final hasDeclare = diploList.any(
              (d) =>
                  d.type == DiplomaticOrderType.declareWar &&
                  d.targetFactionId == warTarget,
            );
            if (!hasDeclare) {
              next = ordersWithAppendedDiplomaticOrder(
                next,
                e.humanPlayerId,
                DiplomaticOrder(
                  type: DiplomaticOrderType.declareWar,
                  targetFactionId: warTarget,
                ),
              );
            }
          }
          next = applyArmyMoveOrderForPlayer(
            next,
            e.humanPlayerId,
            e.moveOrder,
          );
          final engine = OrderEngine(
            initialOrders: next,
            projector: projectOrderEffects,
          );
          final results = engine.validatePlayerOrdersWithContext(
            g,
            topo,
            e.humanPlayerId,
          );
          if (!results.every((r) => r.isAccepted)) {
            _logEvent.e(
              'ui: army move rejected: merged draft failed order validation',
            );
            _showSnackBar(
              const ShowSnackBarEvent(
                message: 'Could not apply army move. Orders are invalid.',
              ),
            );
            assert(
              results.every((r) => r.isAccepted),
              'ArmyMoveRequestedEvent produced an invalid draft',
            );
            return;
          }
          ref.read(currentOrdersProvider.notifier).replaceAll(next);
        });
      }),
      bus.on<TrainMilitaryBuildOrdersCommittedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'TrainMilitaryBuildOrdersCommittedEvent',
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
                  _mergeTrainMilitaryOrdersForPlayer(
                    current: o,
                    game: g,
                    humanPlayerId: pid,
                    newFromDialog: e.orders,
                  ),
                );
          },
        );
      }),
      bus.on<CombatModeChosenEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession('CombatModeChosenEvent', () {
          final g = ref.read(currentGameProvider);
          final updated = applyCombatModeChoiceToGame(g, e.mode);
          if (updated == null) {
            _logEvent.w(
              'CombatModeChosenEvent received without an active game; ignoring',
            );
            return;
          }
          if (identical(updated, g)) {
            return;
          }
          ref.read(currentGameProvider.notifier).setGame(updated);
          ref
              .read(gameServiceProvider)
              .saveGame(
                ref
                    .read(observeSessionProvider.notifier)
                    .prepareGameForPersistence(updated),
              );
          _logEvent.i('combat: set default combat mode to ${e.mode.name}');
        });
      }),
    ];
  }
}
