import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_dialogs.dart';
import 'package:colonizethis_app/features/game/widgets/train_civilians_dialog.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';

import 'app_event_handler.dart';

/// [OpenDialogEvent] id for [TrainCiviliansDialog]. SPEC/program/app-ui-wiring.md.
const String trainCiviliansDialogId = 'train_civilians';

/// [OpenDialogEvent] id for [GrantOrSubsidyDialog]. SPEC/program/app-ui-wiring.md.
const String grantOrSubsidyDialogId = 'grant_or_subsidy';

/// [OpenDialogEvent] id for [NewGameLeaderSelectionDialog]. SPEC/program/app-ui-wiring.md.
const String newGameLeaderSelectionDialogId = 'new_game_leader_selection';

final _log = Logger();

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
          final container = ProviderScope.containerOf(ctx);
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
            onConfirmed: (leaderVariantByGpId) {
              final config = GameSetupConfig(
                selectedGreatPowerIds: baseConfig.selectedGreatPowerIds,
                leaderVariantByGpId: leaderVariantByGpId,
                continentCount: baseConfig.continentCount,
                minorNationCount: baseConfig.minorNationCount,
                tribeCount: baseConfig.tribeCount,
                numProvincesOldWorld: baseConfig.numProvincesOldWorld,
                numProvincesNewWorld: baseConfig.numProvincesNewWorld,
                minProvincesPerMinor: baseConfig.minProvincesPerMinor,
                seed: baseConfig.seed,
                startingResources: baseConfig.startingResources,
              );
              final service = container.read(gameServiceProvider);
              final game = service.createNewGame(config: config);
              container.read(currentGameProvider.notifier).state = game;
              container.read(appEventBusProvider).emit(
                    const NavigateToRouteEvent(Routes.game),
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
              final existing = o.buildUnitOrdersByPlayerId[humanPlayerId] ?? [];
              container.read(currentOrdersProvider.notifier).state = o.copyWith(
                buildUnitOrdersByPlayerId: {
                  ...o.buildUnitOrdersByPlayerId,
                  humanPlayerId: [...existing, ...newOrders],
                },
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
    _log.d('ui:app_event: AppEventHandler bound');
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
