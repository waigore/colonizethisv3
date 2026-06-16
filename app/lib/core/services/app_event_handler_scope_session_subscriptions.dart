part of 'app_event_handler_scope.dart';

int civilianWorkUpsertValidationPassCountForTests = 0;

void resetCivilianWorkUpsertValidationPassCountForTests() {
  civilianWorkUpsertValidationPassCountForTests = 0;
}

extension _SessionCommands on _AppEventHandlerScopeState {
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
    final nextGame = result.game;
    if (nextGame == null) {
      _logEvent.w(result.message);
      _showSnackBar(ShowSnackBarEvent(message: result.message));
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
    _showSnackBar(ShowSnackBarEvent(message: result.message));
  }

  bool _rejectUiMutationIfObserving() => rejectUiMutationIfObserving(
        shell: ref.read(shellPlayerContextProvider),
        showSnack: _showSnackBar,
      );

  List<StreamSubscription<dynamic>> _sessionCommandListeners(AppEventBus bus) {
    return [
      bus.on<SetObserveModeOffEvent>().listen((_) {
        _unlessTurnResolutionBlocksSession( 'SetObserveModeOffEvent', () {
          ref.read(observeModeSessionHandlerProvider).applySetObserveModeOff();
        });
      }),
      bus.on<SetObserveModeGlobalEvent>().listen((_) {
        _unlessTurnResolutionBlocksSession(
          'SetObserveModeGlobalEvent',
          () {
            ref.read(observeModeSessionHandlerProvider).applySetObserveModeGlobal();
          },
        );
      }),
      bus.on<SetObserveModePlayerEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'SetObserveModePlayerEvent',
          () {
            ref
                .read(observeModeSessionHandlerProvider)
                .applySetObserveModePlayer(e.targetPlayerId);
          },
        );
      }),
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
      bus.on<NavalFleetsUpdatedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession( 'NavalFleetsUpdatedEvent', () {
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
      bus.on<LandArmiesUpdatedEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession( 'LandArmiesUpdatedEvent', () {
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
        _unlessTurnResolutionBlocksSession( 'ArmySplitRequestedEvent', () {
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
        _unlessTurnResolutionBlocksSession( 'ArmyMoveRequestedEvent', () {
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
      bus.on<SpawnDebugCivilianAtCapitalEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'SpawnDebugCivilianAtCapitalEvent',
          () {
            final current = ref.read(currentGameProvider);
            _applyDebugCommand(
              applyDebugCivilianSpawnAtCapital(currentGame: current, event: e),
            );
          },
        );
      }),
      bus.on<SpawnDebugRegimentAtCapitalEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'SpawnDebugRegimentAtCapitalEvent',
          () {
            final current = ref.read(currentGameProvider);
            _applyDebugCommand(
              applyDebugRegimentSpawnAtCapital(currentGame: current, event: e),
            );
          },
        );
      }),
      bus.on<SpawnDebugShipAtCapitalHomeFleetEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'SpawnDebugShipAtCapitalHomeFleetEvent',
          () {
            final current = ref.read(currentGameProvider);
            _applyDebugCommand(
              applyDebugShipSpawnAtCapitalHomeFleet(
                currentGame: current,
                event: e,
              ),
            );
          },
        );
      }),
      bus.on<CreditDebugTreasuryEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession( 'CreditDebugTreasuryEvent', () {
          final current = ref.read(currentGameProvider);
          _applyDebugCommand(
            applyDebugTreasuryCredit(currentGame: current, event: e),
          );
        });
      }),
      bus.on<CreditDebugWorkerPoolEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'CreditDebugWorkerPoolEvent',
          () {
            final current = ref.read(currentGameProvider);
            _applyDebugCommand(
              applyDebugWorkerPoolCredit(currentGame: current, event: e),
            );
          },
        );
      }),
      bus.on<CreditDebugStockpileCommodityEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'CreditDebugStockpileCommodityEvent',
          () {
            final current = ref.read(currentGameProvider);
            _applyDebugCommand(
              applyDebugStockpileCredit(currentGame: current, event: e),
            );
          },
        );
      }),
      bus.on<FlipDebugProvinceOwnershipEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'FlipDebugProvinceOwnershipEvent',
          () {
            final current = ref.read(currentGameProvider);
            final mapData = current == null
                ? null
                : ref.read(gameServiceProvider).getMapData(current.id);
            final result = applyDebugFlipProvinceOwnership(
              currentGame: current,
              event: e,
              combinedTopology:
                  mapData?.combinedTopology ?? const MapTopology(),
              topologyByRegion: mapData?.topologyByRegion,
            );
            _applyDebugCommand(result);
          },
        );
      }),
      bus.on<RevealDebugProvinceEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession( 'RevealDebugProvinceEvent', () {
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
        });
      }),
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
      bus.on<CombatModeChosenEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession( 'CombatModeChosenEvent', () {
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
