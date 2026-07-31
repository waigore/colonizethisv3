import 'dart:async';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'app_event_handler_scope_session_helpers.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/observe_session_provider.dart';
import '../../../features/game/widgets/shell/shell_player_context.dart';
import 'app_event_handler_scope_train_orders.dart';

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
      bus.on<CivilianMoveRequestedEvent>().listen((e) {
        unlessTurnResolutionBlocksSession('CivilianMoveRequestedEvent', () {
          if (rejectUiMutationIfObserving()) return;
          final g = ref.read(currentGameProvider);
          if (g == null) return;
          final topo =
              ref
                  .read(gameServiceProvider)
                  .getMapData(g.id)
                  ?.combinedTopology ??
              const MapTopology();
          final tileMaps = ref
              .read(gameServiceProvider)
              .getMapData(g.id)
              ?.tileMapByRegion;
          final o = ref.read(currentOrdersProvider);
          final next = applyCivilianMoveOrderForPlayer(
            o,
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
            tileMapByRegion: tileMaps,
          );
          if (!results.every((r) => r.isAccepted)) {
            appEventHandlerScopeLog.e(
              'ui: civilian move rejected: merged draft failed order validation',
            );
            showSnackBarForEvent(
              const ShowSnackBarEvent(
                message: 'Could not apply Spy relocate. Orders are invalid.',
              ),
            );
            assert(
              results.every((r) => r.isAccepted),
              'CivilianMoveRequestedEvent produced an invalid draft',
            );
            return;
          }
          ref.read(currentOrdersProvider.notifier).replaceAll(next);
        });
      }),
      bus.on<RemovePendingCivilianMoveRequestedEvent>().listen((e) {
        unlessTurnResolutionBlocksSession(
          'RemovePendingCivilianMoveRequestedEvent',
          () {
            if (rejectUiMutationIfObserving()) return;
            final current = ref.read(currentOrdersProvider);
            final updated = removePendingCivilianMoveForUnit(
              orders: current,
              humanPlayerId: e.playerId,
              unitId: e.unitId,
            );
            ref.read(currentOrdersProvider.notifier).replaceAll(updated);
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
