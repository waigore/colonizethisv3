import 'dart:async';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart' show projectOrderEffects;
import 'package:colonizethis_world/colonizethis_world.dart'
    show applyArmyCombine, applyArmySplit;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'app_event_handler_scope_session_helpers.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/observe_session_provider.dart';
import '../../../features/game/widgets/shell/shell_player_context.dart';
import 'app_event_handler_scope_train_orders.dart';

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
