import 'dart:async';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import '../../../features/game/widgets/shell/shell_player_context.dart';
import 'app_event_handler_scope_session_helpers.dart';
import 'app_event_handler_scope_train_orders.dart';

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
