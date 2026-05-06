part of 'app_event_handler_scope.dart';

extension _SessionCommands on _AppEventHandlerScopeState {
  void _applyDebugCommand(DebugCommandResult result) {
    final nextGame = result.game;
    if (nextGame == null) {
      _logEvent.w(result.message);
      _showSnackBar(ShowSnackBarEvent(message: result.message));
      return;
    }
    ref.read(currentGameProvider.notifier).setGame(nextGame);
    ref.read(gameServiceProvider).saveGame(nextGame);
    _showSnackBar(ShowSnackBarEvent(message: result.message));
  }

  List<StreamSubscription<dynamic>> _sessionCommandListeners(AppEventBus bus) {
    return [
      bus.on<RemovePendingWorkOrderRequestedEvent>().listen((e) {
        final current = ref.read(currentOrdersProvider);
        final updated = removePendingWorkOrderAt(current, e.playerId, e.index);
        ref.read(currentOrdersProvider.notifier).replaceAll(updated);
      }),
      bus.on<UpsertPendingCivilianWorkOrderRequestedEvent>().listen((e) {
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
              ref.read(gameServiceProvider).getMapData(game.id)?.combinedTopology ??
              const MapTopology();
          final tileMaps =
              ref.read(gameServiceProvider).getMapData(game.id)?.tileMapByRegion;
          final engine = OrderEngine(initialOrders: next);
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
      }),
      bus.on<CancelInProgressCivilianWorkRequestedEvent>().listen((e) {
        final game = ref.read(currentGameProvider);
        if (game == null) return;
        final newGame = clearUnitCurrentWork(game, e.unitId);
        ref.read(currentGameProvider.notifier).setGame(newGame);
        ref.read(gameServiceProvider).saveGame(newGame);
      }),
      bus.on<NavalFleetsUpdatedEvent>().listen((e) {
        ref.read(currentGameProvider.notifier).setGame(e.game);
      }),
      bus.on<NavalSplitFleetRequestedEvent>().listen((e) {
        final g = ref.read(currentGameProvider);
        if (g == null) return;
        final newGame = applyNavalSplitFleet(
          game: g,
          humanPlayerId: e.humanPlayerId,
          originalFleetId: e.originalFleetId,
          shipInstanceIdsToNewFleet: e.shipInstanceIdsToNewFleet,
        );
        bus.emit(NavalFleetsUpdatedEvent(game: newGame));
      }),
      bus.on<NavalTransferShipsRequestedEvent>().listen((e) {
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
      }),
      bus.on<NavalMoveFleetRequestedEvent>().listen((e) {
        final o = ref.read(currentOrdersProvider);
        ref
            .read(currentOrdersProvider.notifier)
            .replaceAll(
              applyNavalMoveOrderForPlayer(o, e.humanPlayerId, e.moveOrder),
            );
      }),
      bus.on<LandArmiesUpdatedEvent>().listen((e) {
        ref.read(currentGameProvider.notifier).setGame(e.game);
      }),
      bus.on<ArmyCombineRequestedEvent>().listen((e) {
        final g = ref.read(currentGameProvider);
        if (g == null) return;
        final next = applyArmyCombine(
          game: g,
          playerId: e.humanPlayerId,
          armyIds: e.armyIds,
        );
        bus.emit(LandArmiesUpdatedEvent(game: next));
      }),
      bus.on<ArmySplitRequestedEvent>().listen((e) {
        final g = ref.read(currentGameProvider);
        if (g == null) return;
        final next = applyArmySplit(
          game: g,
          playerId: e.humanPlayerId,
          sourceArmyId: e.sourceArmyId,
          unitIdsToMove: e.unitIdsToMove,
        );
        bus.emit(LandArmiesUpdatedEvent(game: next));
      }),
      bus.on<ArmyMoveRequestedEvent>().listen((e) {
        final g = ref.read(currentGameProvider);
        if (g == null) return;
        final topo =
            ref.read(gameServiceProvider).getMapData(g.id)?.combinedTopology ??
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
        next = applyArmyMoveOrderForPlayer(next, e.humanPlayerId, e.moveOrder);
        final engine = OrderEngine(initialOrders: next);
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
      }),
      bus.on<TrainCivilianBuildOrdersCommittedEvent>().listen((e) {
        final g = ref.read(currentGameProvider);
        if (g == null) return;
        final pid = _AppEventHandlerScopeState._humanPlayerId(g);
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
      }),
      bus.on<TrainMilitaryBuildOrdersCommittedEvent>().listen((e) {
        final g = ref.read(currentGameProvider);
        if (g == null) return;
        final pid = _AppEventHandlerScopeState._humanPlayerId(g);
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
      }),
      bus.on<SpawnDebugCivilianAtCapitalEvent>().listen((e) {
        final current = ref.read(currentGameProvider);
        _applyDebugCommand(
          applyDebugCivilianSpawnAtCapital(currentGame: current, event: e),
        );
      }),
      bus.on<SpawnDebugRegimentAtCapitalEvent>().listen((e) {
        final current = ref.read(currentGameProvider);
        _applyDebugCommand(
          applyDebugRegimentSpawnAtCapital(currentGame: current, event: e),
        );
      }),
      bus.on<SpawnDebugShipAtCapitalHomeFleetEvent>().listen((e) {
        final current = ref.read(currentGameProvider);
        _applyDebugCommand(
          applyDebugShipSpawnAtCapitalHomeFleet(currentGame: current, event: e),
        );
      }),
      bus.on<CreditDebugTreasuryEvent>().listen((e) {
        final current = ref.read(currentGameProvider);
        _applyDebugCommand(
          applyDebugTreasuryCredit(currentGame: current, event: e),
        );
      }),
      bus.on<CreditDebugStockpileCommodityEvent>().listen((e) {
        final current = ref.read(currentGameProvider);
        _applyDebugCommand(
          applyDebugStockpileCredit(currentGame: current, event: e),
        );
      }),
      bus.on<FlipDebugProvinceOwnershipEvent>().listen((e) {
        final current = ref.read(currentGameProvider);
        final mapData = current == null
            ? null
            : ref.read(gameServiceProvider).getMapData(current.id);
        final result = applyDebugFlipProvinceOwnership(
          currentGame: current,
          event: e,
          combinedTopology: mapData?.combinedTopology ?? const MapTopology(),
          topologyByRegion: mapData?.topologyByRegion,
        );
        _applyDebugCommand(result);
      }),
      bus.on<RevealDebugProvinceEvent>().listen((e) {
        final current = ref.read(currentGameProvider);
        final mapData = current == null
            ? null
            : ref.read(gameServiceProvider).getMapData(current.id);
        final result = applyDebugRevealProvince(
          currentGame: current,
          event: e,
          combinedTopology: mapData?.combinedTopology ?? const MapTopology(),
          topologyByRegion: mapData?.topologyByRegion,
        );
        _applyDebugCommand(result);
      }),
      bus.on<AppendDiplomaticOrderRequestedEvent>().listen((e) {
        final current = ref.read(currentOrdersProvider);
        ref
            .read(currentOrdersProvider.notifier)
            .replaceAll(
              current.appendDiplomaticOrderForPlayer(e.playerId, e.order),
            );
      }),
      bus.on<RemoveDiplomaticOrderRequestedEvent>().listen((e) {
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
      }),
      bus.on<CombatModeChosenEvent>().listen((e) {
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
        ref.read(gameServiceProvider).saveGame(updated);
        _logEvent.i('combat: set default combat mode to ${e.mode.name}');
      }),
    ];
  }
}
