import 'dart:async';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/observe_session_provider.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_order_helpers.dart';
import 'app_event_handler_break_alliance_immediately.dart'
    show applyBreakAllianceImmediately;
import 'app_event_handler_scope_log.dart';
import 'app_event_handler_scope_session_helpers.dart';

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
