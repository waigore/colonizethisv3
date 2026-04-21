import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_dialogs.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_order_helpers.dart';
import 'package:colonizethis_app/features/game/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/combat/quick_battle_result_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train_civilians_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train_military_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/turn_news_dialog.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/features/shell/new_game_setup_flow.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';

import 'app_event_handler.dart';

/// [OpenDialogEvent] id for [TrainCiviliansDialog]. SPEC/program/app-ui-wiring.md.
const String trainCiviliansDialogId = 'train_civilians';

/// [OpenDialogEvent] id for [TrainMilitaryDialog]. SPEC/program/app-ui-wiring.md.
const String trainMilitaryDialogId = 'train_military';

/// [OpenDialogEvent] id for [GrantOrSubsidyDialog]. SPEC/program/app-ui-wiring.md.
const String grantOrSubsidyDialogId = 'grant_or_subsidy';

/// [OpenDialogEvent] id for [NewGameLeaderSelectionDialog]. SPEC/program/app-ui-wiring.md.
const String newGameLeaderSelectionDialogId = 'new_game_leader_selection';

/// Smaller than [GameSetupConfig.defaultConfig]: integration tests compile with
/// `CT_E2E=true` and must stay inside CI wall clocks (not the locked full-init
/// 60/30 profile). Production `main` / widget tests use [GameSetupConfig.defaultConfig].
GameSetupConfig _ctE2eNewGameLeaderTemplateConfig() {
  final d = GameSetupConfig.defaultConfig;
  return GameSetupConfig(
    selectedGreatPowerIds: d.selectedGreatPowerIds,
    leaderVariantByGpId: d.leaderVariantByGpId,
    continentCount: 2,
    minorNationCount: 2,
    tribeCount: 4,
    numProvincesOldWorld: 24,
    numProvincesNewWorld: 12,
    minProvincesPerMinor: 2,
    seed: d.seed,
    startingResources: d.startingResources,
    preferredInitialMapZoomMultiplier: d.preferredInitialMapZoomMultiplier,
    initTownRoadWiringRegionIds: d.initTownRoadWiringRegionIds,
  );
}

/// [OpenDialogEvent] id for [CombatModeChoiceDialog]. SPEC/program/app-ui-wiring.md.
const String combatModeChoiceDialogId = 'combat_mode_choice';

/// [OpenDialogEvent] id for [QuickBattleResultDialog]. SPEC/program/app-ui-wiring.md.
const String quickBattleResultDialogId = 'quick_battle_result';

final _logShell = packageLogger('shell');
final _logEvent = packageLogger('event');

/// Applies a chosen combat mode to the current game session state.
@visibleForTesting
Game? applyCombatModeChoiceToGame(Game? currentGame, CombatMode chosenMode) {
  if (currentGame == null) {
    return null;
  }
  if (currentGame.defaultCombatMode == chosenMode) {
    return currentGame;
  }
  return currentGame.copyWith(defaultCombatMode: chosenMode);
}

/// Replaces pending train-at-capital civilian [BuildUnitOrder]s for [humanPlayerId];
/// keeps military, naval, and other build orders. Matches [TrainCiviliansDialog] semantics.
Orders _mergeTrainCivilianOrdersForPlayer({
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

/// Replaces pending train-at-capital military [BuildUnitOrder]s for [humanPlayerId];
/// keeps civilian, naval, and other build orders. Matches [TrainMilitaryDialog] semantics.
Orders _mergeTrainMilitaryOrdersForPlayer({
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

/// Binds [AppEventHandler] to [appNavigatorKey] for the app lifetime.
/// SPEC/program/app-event-bus.md (handler); SPEC/program/app-ui-wiring.md (dialog registration).
class AppEventHandlerScope extends ConsumerStatefulWidget {
  const AppEventHandlerScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppEventHandlerScope> createState() =>
      _AppEventHandlerScopeState();
}

class _AppEventHandlerScopeState extends ConsumerState<AppEventHandlerScope> {
  AppEventHandler? _handler;
  bool _bound = false;
  final List<StreamSubscription<dynamic>> _sessionCommandSubs = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bound) {
      return;
    }
    _bound = true;
    final bus = ref.read(appEventBusProvider);
    _handler = AppEventHandler(
      bus: bus,
      navigatorKey: appNavigatorKey,
      dialogBuilders: {
        newGameLeaderSelectionDialogId: (ctx, _) {
          final baseConfig = kCtE2EEnabled
              ? _ctE2eNewGameLeaderTemplateConfig()
              : GameSetupConfig.defaultConfig;
          final naming = defaultNamingConfig;
          final initialSelections = <String, String>{};
          for (final gpId in baseConfig.selectedGreatPowerIds) {
            final gp = naming.gpById(gpId);
            if (gp != null && gp.leaderVariants.isNotEmpty) {
              initialSelections[gpId] = gp.defaultLeaderVariantId;
            }
          }
          return NewGameLeaderSelectionDialog(
            baseConfig: baseConfig,
            naming: naming,
            initialLeaderByGpId: initialSelections,
            onCancel: () => Navigator.of(ctx).pop(),
            onConfirmed: (orderedGreatPowerIds, leaderVariantByGpId, seed) {
              final navCtx = appNavigatorKey.currentContext;
              if (navCtx == null) {
                _logShell.w(
                  'appNavigatorKey has no context; skipping new game setup',
                );
                return;
              }
              final rootContainer = ProviderScope.containerOf(navCtx);
              final templateConfig = GameSetupConfig(
                selectedGreatPowerIds: orderedGreatPowerIds,
                leaderVariantByGpId: leaderVariantByGpId,
                continentCount: baseConfig.continentCount,
                minorNationCount: baseConfig.minorNationCount,
                tribeCount: baseConfig.tribeCount,
                numProvincesOldWorld: baseConfig.numProvincesOldWorld,
                numProvincesNewWorld: baseConfig.numProvincesNewWorld,
                minProvincesPerMinor: baseConfig.minProvincesPerMinor,
                seed: seed,
                startingResources: baseConfig.startingResources,
                initTownRoadWiringRegionIds:
                    baseConfig.initTownRoadWiringRegionIds,
              );
              unawaited(
                runNewGameSetupAfterLeaderPick(
                  container: rootContainer,
                  templateConfig: templateConfig,
                ),
              );
            },
          );
        },
        trainCiviliansDialogId: (ctx, _) {
          final container = ProviderScope.containerOf(ctx);
          final game = container.read(currentGameProvider);
          if (game == null) {
            return const SizedBox.shrink();
          }
          final humanPlayerId = _humanPlayerId(game);
          final orders = container.read(currentOrdersProvider);
          return TrainCiviliansDialog(
            game: game,
            humanPlayerId: humanPlayerId,
            currentOrders: orders,
            bus: container.read(appEventBusProvider),
          );
        },
        trainMilitaryDialogId: (ctx, _) {
          final container = ProviderScope.containerOf(ctx);
          final game = container.read(currentGameProvider);
          if (game == null) {
            return const SizedBox.shrink();
          }
          final humanPlayerId = _humanPlayerId(game);
          final orders = container.read(currentOrdersProvider);
          return TrainMilitaryDialog(
            game: game,
            humanPlayerId: humanPlayerId,
            currentOrders: orders,
            bus: container.read(appEventBusProvider),
          );
        },
        grantOrSubsidyDialogId: (ctx, params) {
          final container = ProviderScope.containerOf(ctx);
          final game = container.read(currentGameProvider);
          if (game == null) {
            return const SizedBox.shrink();
          }
          final humanPlayerId = _humanPlayerId(game);
          final bus = container.read(appEventBusProvider);
          final isSubsidy = params?['isSubsidy'] as bool? ?? false;
          final targetFactionId = params?['targetFactionId'] as String? ?? '';
          return GrantOrSubsidyDialog(
            game: game,
            humanPlayerId: humanPlayerId,
            targetFactionId: targetFactionId,
            isSubsidy: isSubsidy,
            bus: bus,
          );
        },
        combatModeChoiceDialogId: (ctx, params) {
          final container = ProviderScope.containerOf(ctx);
          final bus = container.read(appEventBusProvider);
          final provinceName = params?['provinceName'] as String? ?? '';
          final isCapitalSiege = params?['isCapitalSiege'] as bool? ?? false;
          return CombatModeChoiceDialog(
            bus: bus,
            provinceName: provinceName,
            isCapitalSiege: isCapitalSiege,
          );
        },
        quickBattleResultDialogId: (ctx, params) {
          final result = params?['result'] as QuickBattleResult?;
          if (result == null) {
            return const SizedBox.shrink();
          }
          final attackerName = params?['attackerName'] as String? ?? 'Attacker';
          final defenderName = params?['defenderName'] as String? ?? 'Defender';
          return QuickBattleResultDialog(
            result: result,
            attackerName: attackerName,
            defenderName: defenderName,
          );
        },
        turnNewsDialogId: (ctx, params) {
          final container = ProviderScope.containerOf(ctx);
          final game = container.read(currentGameProvider);
          final digest = params?['digest'] as TurnNewsDigest?;
          final newTurnNumber = params?['newTurnNumber'] as int?;
          if (game == null || digest == null || newTurnNumber == null) {
            return const SizedBox.shrink();
          }
          return TurnNewsDialog(
            game: game,
            digest: digest,
            newTurnNumber: newTurnNumber,
          );
        },
      },
      onShowSnackBar: _showSnackBar,
    );
    _handler!.bind();

    _sessionCommandSubs.addAll([
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
        ref
            .read(currentOrdersProvider.notifier)
            .replaceAll(
              current.copyWith(
                moveOrdersByPlayerId: {
                  ...current.moveOrdersByPlayerId,
                  playerId: nextMoveOrders,
                },
                workOrdersByPlayerId: {
                  ...current.workOrdersByPlayerId,
                  playerId: nextWorkOrders,
                },
              ),
            );
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
        final pid = _humanPlayerId(g);
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
        final pid = _humanPlayerId(g);
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
    ]);
    _logEvent.d('AppEventHandler bound; session command listeners attached');
  }

  void _showSnackBar(ShowSnackBarEvent event) {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(ctx);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(event.message),
        action: event.actionLabel != null && event.action != null
            ? SnackBarAction(
                label: event.actionLabel!,
                onPressed: event.action!,
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    for (final s in _sessionCommandSubs) {
      s.cancel();
    }
    _sessionCommandSubs.clear();
    _handler?.unbind();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  static String _humanPlayerId(Game game) {
    for (final p in game.players) {
      if (p.isHuman) return p.id;
    }
    return game.players.first.id;
  }
}
