import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/features/game/widgets/train_civilians_dialog.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';

import 'app_event_handler.dart';

/// [OpenDialogEvent] id for [TrainCiviliansDialog]. SPEC/program/app-event-bus.md.
const String trainCiviliansDialogId = 'train_civilians';

final _log = Logger();

/// Binds [AppEventHandler] to [appNavigatorKey] for the app lifetime.
/// SPEC/program/app-event-bus.md.
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
              final existing =
                  o.buildUnitOrdersByPlayerId[humanPlayerId] ?? [];
              container.read(currentOrdersProvider.notifier).state = o
                  .copyWith(
                    buildUnitOrdersByPlayerId: {
                      ...o.buildUnitOrdersByPlayerId,
                      humanPlayerId: [...existing, ...newOrders],
                    },
                  );
            },
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
