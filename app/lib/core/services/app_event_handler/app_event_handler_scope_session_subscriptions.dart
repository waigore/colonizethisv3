import 'dart:async';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import '../observe/observe_mode_session_handler.dart' as observe_session;
import 'app_event_handler_scope_session_helpers.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/observe_session_provider.dart';
import '../../../features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_order_helpers.dart';
import '../debug/app_event_handler_debug_flip_province.dart'
    show applyDebugFlipProvinceOwnership;
import '../debug/app_event_handler_debug_reveal_province.dart'
    show applyDebugRevealProvince;
import '../debug/app_event_handler_debug_set_diplomacy.dart'
    show applyDebugSetDiplomacyRelation;
import '../debug/app_event_handler_debug_spawn_civilian.dart'
    show applyDebugCivilianSpawnAtCapital;
import '../debug/app_event_handler_debug_spawn_regiment.dart'
    show applyDebugRegimentSpawnAtCapital;
import '../debug/app_event_handler_debug_spawn_ship.dart'
    show applyDebugShipSpawnAtCapitalHomeFleet;
import '../debug/app_event_handler_debug_stockpile.dart'
    show applyDebugStockpileCredit;
import '../debug/app_event_handler_debug_treasury.dart'
    show applyDebugTreasuryCredit;
import '../debug/app_event_handler_debug_worker_pool.dart'
    show applyDebugWorkerPoolCredit;

mixin AppEventHandlerScopeSessionObserveListeners
    on AppEventHandlerScopeSessionHelpers {
  List<StreamSubscription<dynamic>> observeSessionListeners(AppEventBus bus) {
    return [
      bus.on<SetObserveModeOffEvent>().listen((_) {
        unlessTurnResolutionBlocksSession('SetObserveModeOffEvent', () {
          ref.read(observe_session.observeModeSessionHandlerProvider).applySetObserveModeOff();
        });
      }),
      bus.on<SetObserveModeGlobalEvent>().listen((_) {
        unlessTurnResolutionBlocksSession('SetObserveModeGlobalEvent', () {
          ref
              .read(observe_session.observeModeSessionHandlerProvider)
              .applySetObserveModeGlobal();
        });
      }),
      bus.on<SetObserveModePlayerEvent>().listen((e) {
        unlessTurnResolutionBlocksSession('SetObserveModePlayerEvent', () {
          ref
              .read(observe_session.observeModeSessionHandlerProvider)
              .applySetObserveModePlayer(e.targetPlayerId);
        });
      }),
    ];
  }
}


mixin AppEventHandlerScopeSessionCivilianWorkListeners
    on AppEventHandlerScopeSessionHelpers {
  List<StreamSubscription<dynamic>> civilianWorkSessionListeners(
    AppEventBus bus,
  ) {
    return [
      bus.on<RemovePendingWorkOrderRequestedEvent>().listen((e) {
        unlessTurnResolutionBlocksSession(
          'RemovePendingWorkOrderRequestedEvent',
          () {
            if (rejectUiMutationIfObserving()) return;
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
        unlessTurnResolutionBlocksSession(
          'UpsertPendingCivilianWorkOrderRequestedEvent',
          () {
            if (rejectUiMutationIfObserving()) return;
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
                appEventHandlerScopeLog.e(
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
                showSnackBarForEvent(ShowSnackBarEvent(message: message));
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
        unlessTurnResolutionBlocksSession(
          'CancelInProgressCivilianWorkRequestedEvent',
          () {
            if (rejectUiMutationIfObserving()) return;
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
        unlessTurnResolutionBlocksSession(
          'TrainCivilianBuildOrdersCommittedEvent',
          () {
            if (rejectUiMutationIfObserving()) return;
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
                  mergeTrainCivilianOrdersForPlayer(
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


mixin AppEventHandlerScopeSessionNavalListeners
    on AppEventHandlerScopeSessionHelpers {
  List<StreamSubscription<dynamic>> navalSessionListeners(AppEventBus bus) {
    return [
      bus.on<NavalFleetsUpdatedEvent>().listen((e) {
        unlessTurnResolutionBlocksSession('NavalFleetsUpdatedEvent', () {
          ref.read(currentGameProvider.notifier).setGame(e.game);
        });
      }),
      bus.on<NavalSplitFleetRequestedEvent>().listen((e) {
        unlessTurnResolutionBlocksSession('NavalSplitFleetRequestedEvent', () {
          if (rejectUiMutationIfObserving()) return;
          final g = ref.read(currentGameProvider);
          if (g == null) return;
          final newGame = applyNavalSplitFleet(
            game: g,
            humanPlayerId: e.humanPlayerId,
            originalFleetId: e.originalFleetId,
            shipInstanceIdsToNewFleet: e.shipInstanceIdsToNewFleet,
          );
          bus.emit(NavalFleetsUpdatedEvent(game: newGame));
        });
      }),
      bus.on<NavalTransferShipsRequestedEvent>().listen((e) {
        unlessTurnResolutionBlocksSession(
          'NavalTransferShipsRequestedEvent',
          () {
            if (rejectUiMutationIfObserving()) return;
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
        unlessTurnResolutionBlocksSession('NavalMoveFleetRequestedEvent', () {
          if (rejectUiMutationIfObserving()) return;
          final o = ref.read(currentOrdersProvider);
          ref
              .read(currentOrdersProvider.notifier)
              .replaceAll(
                applyNavalMoveOrderForPlayer(o, e.humanPlayerId, e.moveOrder),
              );
        });
      }),
      bus.on<TrainNavalBuildOrdersCommittedEvent>().listen((e) {
        unlessTurnResolutionBlocksSession(
          'TrainNavalBuildOrdersCommittedEvent',
          () {
            if (rejectUiMutationIfObserving()) return;
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
                  mergeTrainNavalOrdersForPlayer(
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


mixin AppEventHandlerScopeSessionArmyListeners
    on AppEventHandlerScopeSessionHelpers {
  List<StreamSubscription<dynamic>> armySessionListeners(AppEventBus bus) {
    return [
      bus.on<LandArmiesUpdatedEvent>().listen((e) {
        unlessTurnResolutionBlocksSession('LandArmiesUpdatedEvent', () {
          ref.read(currentGameProvider.notifier).setGame(e.game);
        });
      }),
      bus.on<ArmyCombineRequestedEvent>().listen((e) {
        unlessTurnResolutionBlocksSession('ArmyCombineRequestedEvent', () {
          if (rejectUiMutationIfObserving()) return;
          final g = ref.read(currentGameProvider);
          if (g == null) return;
          final next = applyArmyCombine(
            game: g,
            playerId: e.humanPlayerId,
            armyIds: e.armyIds,
          );
          bus.emit(LandArmiesUpdatedEvent(game: next));
        });
      }),
      bus.on<ArmySplitRequestedEvent>().listen((e) {
        unlessTurnResolutionBlocksSession('ArmySplitRequestedEvent', () {
          if (rejectUiMutationIfObserving()) return;
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
        unlessTurnResolutionBlocksSession('ArmyMoveRequestedEvent', () {
          if (rejectUiMutationIfObserving()) return;
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
            appEventHandlerScopeLog.e(
              'ui: army move rejected: merged draft failed order validation',
            );
            showSnackBarForEvent(
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
        unlessTurnResolutionBlocksSession(
          'TrainMilitaryBuildOrdersCommittedEvent',
          () {
            if (rejectUiMutationIfObserving()) return;
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
                  mergeTrainMilitaryOrdersForPlayer(
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
        unlessTurnResolutionBlocksSession('CombatModeChosenEvent', () {
          final g = ref.read(currentGameProvider);
          final updated = applyCombatModeChoiceToGame(g, e.mode);
          if (updated == null) {
            appEventHandlerScopeLog.w(
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
          appEventHandlerScopeLog.i(
            'combat: set default combat mode to ${e.mode.name}',
          );
        });
      }),
    ];
  }
}


mixin AppEventHandlerScopeSessionDiplomacyListeners
    on AppEventHandlerScopeSessionHelpers {
  List<StreamSubscription<dynamic>> diplomacySessionListeners(
    AppEventBus bus,
  ) {
    return [
      bus.on<AppendDiplomaticOrderRequestedEvent>().listen((e) {
        unlessTurnResolutionBlocksSession(
          'AppendDiplomaticOrderRequestedEvent',
          () {
            if (rejectUiMutationIfObserving()) return;
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
        unlessTurnResolutionBlocksSession(
          'RemoveDiplomaticOrderRequestedEvent',
          () {
            if (rejectUiMutationIfObserving()) return;
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
        unlessTurnResolutionBlocksSession('BreakAllianceImmediatelyEvent', () {
          if (rejectUiMutationIfObserving()) return;
          final current = ref.read(currentGameProvider);
          final result = applyBreakAllianceImmediately(
            currentGame: current,
            event: e,
          );
          final nextGame = result.game;
          if (nextGame == null) {
            appEventHandlerScopeLog.w(
              result.message ?? 'Break Alliance rejected.',
            );
            showSnackBarForEvent(
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
        });
      }),
    ];
  }
}


mixin AppEventHandlerScopeSessionDebugListeners
    on AppEventHandlerScopeSessionHelpers {
  List<StreamSubscription<dynamic>> debugSessionListeners(AppEventBus bus) {
    return [
      bus.on<SpawnDebugCivilianAtCapitalEvent>().listen((e) {
        unlessTurnResolutionBlocksSession(
          'SpawnDebugCivilianAtCapitalEvent',
          () {
            final current = ref.read(currentGameProvider);
            applyDebugCommand(
              applyDebugCivilianSpawnAtCapital(currentGame: current, event: e),
            );
          },
        );
      }),
      bus.on<SpawnDebugRegimentAtCapitalEvent>().listen((e) {
        unlessTurnResolutionBlocksSession(
          'SpawnDebugRegimentAtCapitalEvent',
          () {
            final current = ref.read(currentGameProvider);
            applyDebugCommand(
              applyDebugRegimentSpawnAtCapital(currentGame: current, event: e),
            );
          },
        );
      }),
      bus.on<SpawnDebugShipAtCapitalHomeFleetEvent>().listen((e) {
        unlessTurnResolutionBlocksSession(
          'SpawnDebugShipAtCapitalHomeFleetEvent',
          () {
            final current = ref.read(currentGameProvider);
            applyDebugCommand(
              applyDebugShipSpawnAtCapitalHomeFleet(
                currentGame: current,
                event: e,
              ),
            );
          },
        );
      }),
      bus.on<CreditDebugTreasuryEvent>().listen((e) {
        unlessTurnResolutionBlocksSession('CreditDebugTreasuryEvent', () {
          final current = ref.read(currentGameProvider);
          applyDebugCommand(
            applyDebugTreasuryCredit(currentGame: current, event: e),
          );
        });
      }),
      bus.on<CreditDebugWorkerPoolEvent>().listen((e) {
        unlessTurnResolutionBlocksSession('CreditDebugWorkerPoolEvent', () {
          final current = ref.read(currentGameProvider);
          applyDebugCommand(
            applyDebugWorkerPoolCredit(currentGame: current, event: e),
          );
        });
      }),
      bus.on<CreditDebugStockpileCommodityEvent>().listen((e) {
        unlessTurnResolutionBlocksSession(
          'CreditDebugStockpileCommodityEvent',
          () {
            final current = ref.read(currentGameProvider);
            applyDebugCommand(
              applyDebugStockpileCredit(currentGame: current, event: e),
            );
          },
        );
      }),
      bus.on<FlipDebugProvinceOwnershipEvent>().listen((e) {
        unlessTurnResolutionBlocksSession(
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
            applyDebugCommand(result);
          },
        );
      }),
      bus.on<RevealDebugProvinceEvent>().listen((e) {
        unlessTurnResolutionBlocksSession('RevealDebugProvinceEvent', () {
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
          applyDebugCommand(result);
        });
      }),
      bus.on<SetDebugDiplomacyRelationEvent>().listen((e) {
        unlessTurnResolutionBlocksSession(
          'SetDebugDiplomacyRelationEvent',
          () {
            final current = ref.read(currentGameProvider);
            applyDebugCommand(
              applyDebugSetDiplomacyRelation(currentGame: current, event: e),
            );
          },
        );
      }),
    ];
  }
}


mixin AppEventHandlerScopeSessionCommands
    on
        AppEventHandlerScopeSessionHelpers,
        AppEventHandlerScopeSessionObserveListeners,
        AppEventHandlerScopeSessionCivilianWorkListeners,
        AppEventHandlerScopeSessionNavalListeners,
        AppEventHandlerScopeSessionArmyListeners,
        AppEventHandlerScopeSessionDiplomacyListeners,
        AppEventHandlerScopeSessionDebugListeners {
  List<StreamSubscription<dynamic>> sessionCommandListeners(AppEventBus bus) {
    return [
      ...observeSessionListeners(bus),
      ...civilianWorkSessionListeners(bus),
      ...navalSessionListeners(bus),
      ...armySessionListeners(bus),
      ...diplomacySessionListeners(bus),
      ...debugSessionListeners(bus),
    ];
  }
}

Game? applyCombatModeChoiceToGame(Game? currentGame, CombatMode chosenMode) {
  if (currentGame == null) {
    return null;
  }
  if (currentGame.defaultCombatMode == chosenMode) {
    return currentGame;
  }
  return currentGame.copyWith(defaultCombatMode: chosenMode);
}

Orders mergeTrainCivilianOrdersForPlayer({
  required Orders current,
  required Game game,
  required String humanPlayerId,
  required List<BuildUnitOrder> newFromDialog,
}) {
  Player? player;
  for (final p in game.players) {
    if (p.id == humanPlayerId) {
      player = p;
      break;
    }
  }
  final capital = player?.capitalProvinceId;
  final civilianUnitIds = CivilianEconomyCatalog.byId.keys.toSet();
  final existingList =
      current.buildUnitOrdersByPlayerId[humanPlayerId] ??
      const <BuildUnitOrder>[];
  final kept = <BuildUnitOrder>[];
  for (final order in existingList) {
    final isDialogManaged =
        !order.isMilitary &&
        civilianUnitIds.contains(order.unitType) &&
        capital != null &&
        order.spawnProvinceId == capital;
    if (isDialogManaged) {
      continue;
    }
    kept.add(order);
  }
  return current.copyWith(
    buildUnitOrdersByPlayerId: {
      ...current.buildUnitOrdersByPlayerId,
      humanPlayerId: [...kept, ...newFromDialog],
    },
  );
}

Orders mergeTrainMilitaryOrdersForPlayer({
  required Orders current,
  required Game game,
  required String humanPlayerId,
  required List<BuildUnitOrder> newFromDialog,
}) {
  Player? player;
  for (final p in game.players) {
    if (p.id == humanPlayerId) {
      player = p;
      break;
    }
  }
  final capital = player?.capitalProvinceId;
  final regimentIds = RegimentEconomyCatalog.byId.keys.toSet();
  final existingList =
      current.buildUnitOrdersByPlayerId[humanPlayerId] ??
      const <BuildUnitOrder>[];
  final kept = <BuildUnitOrder>[];
  for (final order in existingList) {
    final isDialogManaged =
        order.isMilitary &&
        regimentIds.contains(order.unitType) &&
        capital != null &&
        order.spawnProvinceId == capital;
    if (isDialogManaged) {
      continue;
    }
    kept.add(order);
  }
  return current.copyWith(
    buildUnitOrdersByPlayerId: {
      ...current.buildUnitOrdersByPlayerId,
      humanPlayerId: [...kept, ...newFromDialog],
    },
  );
}

Orders mergeTrainNavalOrdersForPlayer({
  required Orders current,
  required Game game,
  required String humanPlayerId,
  required List<BuildUnitOrder> newFromDialog,
}) {
  Player? player;
  for (final p in game.players) {
    if (p.id == humanPlayerId) {
      player = p;
      break;
    }
  }
  final capital = player?.capitalProvinceId;
  final shipIds = ShipEconomyCatalog.byId.keys.toSet();
  final existingList =
      current.buildUnitOrdersByPlayerId[humanPlayerId] ??
      const <BuildUnitOrder>[];
  final kept = <BuildUnitOrder>[];
  for (final order in existingList) {
    final isDialogManaged =
        !order.isMilitary &&
        shipIds.contains(order.unitType) &&
        capital != null &&
        order.spawnProvinceId == capital;
    if (isDialogManaged) {
      continue;
    }
    kept.add(order);
  }
  return current.copyWith(
    buildUnitOrdersByPlayerId: {
      ...current.buildUnitOrdersByPlayerId,
      humanPlayerId: [...kept, ...newFromDialog],
    },
  );
}

({Game? game, String? message}) applyBreakAllianceImmediately({
  required Game? currentGame,
  required BreakAllianceImmediatelyEvent event,
}) {
  if (currentGame == null) {
    return (game: null, message: 'Break Alliance ignored: no active game.');
  }
  final game = currentGame;
  if (game.worldState.turnState.phase != TurnPhase.orders) {
    return (
      game: null,
      message:
          'Break Alliance rejected: allowed only during human Orders phase.',
    );
  }

  final rel = getRelation(game, event.playerId, event.targetFactionId);
  if (!(rel?.formalAlliance ?? false)) {
    return (
      game: null,
      message: 'Break Alliance rejected: no formal alliance with that faction.',
    );
  }

  final membership = DiplomacyFactionMembership.from(game);
  final turn = game.worldState.turnState.turnNumber;
  final next = applyVoluntaryAllianceBreak(
    game,
    breakerId: event.playerId,
    brokenWithAllyId: event.targetFactionId,
    turn: turn,
    factionMembership: membership,
  );
  if (identical(next, game)) {
    return (
      game: null,
      message: 'Break Alliance rejected: no formal alliance with that faction.',
    );
  }
  return (
    game: next,
    message: 'Alliance with ${event.targetFactionId} broken.',
  );
}
