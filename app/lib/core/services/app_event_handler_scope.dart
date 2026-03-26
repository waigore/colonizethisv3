import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_dialogs.dart';
import 'package:colonizethis_app/features/game/widgets/train_civilians_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train_military_dialog.dart';
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

final _log = Logger();

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
          final baseConfig = GameSetupConfig.defaultConfig;
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
            onConfirmed:
                (
                  orderedGreatPowerIds,
                  leaderVariantByGpId,
                  enforceFairGpOldWorldAssignment,
                ) {
                  final navCtx = appNavigatorKey.currentContext;
                  if (navCtx == null) {
                    _log.w(
                      'shell: appNavigatorKey has no context; skipping new game setup',
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
                    seed: baseConfig.seed,
                    startingResources: baseConfig.startingResources,
                    enforceFairGpOldWorldAssignment:
                        enforceFairGpOldWorldAssignment,
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
            onOrdersChanged: (newOrders) {
              final o = container.read(currentOrdersProvider);
              container
                  .read(currentOrdersProvider.notifier)
                  .state = _mergeTrainCivilianOrdersForPlayer(
                current: o,
                game: game,
                humanPlayerId: humanPlayerId,
                newFromDialog: newOrders,
              );
            },
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
            onOrdersChanged: (newOrders) {
              final o = container.read(currentOrdersProvider);
              container
                  .read(currentOrdersProvider.notifier)
                  .state = _mergeTrainMilitaryOrdersForPlayer(
                current: o,
                game: game,
                humanPlayerId: humanPlayerId,
                newFromDialog: newOrders,
              );
            },
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
      },
      onShowSnackBar: _showSnackBar,
    );
    _handler!.bind();

    _sessionCommandSubs.addAll([
      bus.on<RemovePendingWorkOrderRequestedEvent>().listen((e) {
        final current = ref.read(currentOrdersProvider);
        final updated = removePendingWorkOrderAt(current, e.playerId, e.index);
        ref.read(currentOrdersProvider.notifier).state = updated;
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
    ]);
    _log.d(
      'ui:app_event: AppEventHandler bound; session command listeners attached',
    );
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
