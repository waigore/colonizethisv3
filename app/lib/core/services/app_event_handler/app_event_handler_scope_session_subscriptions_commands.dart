import 'dart:async';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_order_helpers.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/observe_session_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import '../observe/observe_mode_session_handler.dart' as observe_session;
import 'app_event_handler_scope_session_helpers.dart';
import 'app_event_handler_scope_session_subscriptions_army.dart';
import 'app_event_handler_scope_session_subscriptions_civilian_work.dart';
import 'app_event_handler_scope_session_subscriptions_debug.dart';
import 'app_event_handler_scope_session_subscriptions_naval.dart';
import 'app_event_handler_scope_train_orders.dart';

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
