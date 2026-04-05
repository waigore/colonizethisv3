// AppEventHandler: wires AppEventBus events to actual Navigator / showDialog calls.
// Lives at the shell level; dispatches UIActionEvent and UISystemEvent to Flutter APIs.
// SPEC/program/app-event-bus.md (architecture); SPEC/program/app-ui-wiring.md (dialog IDs / wiring).
//
// Usage (in main or shell setup):
//   final handler = AppEventHandler(
//     bus: eventBus,
//     navigatorKey: appNavigatorKey,
//     dialogBuilders: {
//       'settings': (ctx, params) => SettingsDialog(params: params),
//       'confirm':  (ctx, params) => ConfirmDialog(params: params),
//       ...,
//     },
//   );
//   handler.bind();
//
// To request a dialog from anywhere in the app (no direct Navigator coupling):
//   eventBus.emit(const OpenDialogEvent('settings', {'tab': 'audio'}));
//
// To request navigation:
//   eventBus.emit(const NavigateToRouteEvent('/game/settings'));

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/routes.dart';
import '../../config/constants.dart';
import '../../features/game/widgets/civilian_units_panel.dart';
import '../../features/game/widgets/military_units_panel.dart';
import '../../features/game/widgets/naval_units_panel.dart';
import '../../features/game/widgets/pause_menu_panel.dart';
import '../../providers/app_event_bus_provider.dart';
import '../../providers/game_service_provider.dart';
import '../../providers/games_provider.dart';

typedef DialogBuilder =
    Widget Function(BuildContext context, Map<String, Object?>? params);

final _log = appLogger('event');

class AppEventHandler {
  AppEventHandler({
    required AppEventBus bus,
    required GlobalKey<NavigatorState> navigatorKey,
    Map<String, DialogBuilder>? dialogBuilders,
    Map<String, Widget Function(BuildContext, Map<String, Object?>?)>?
    panelBuilders,
    void Function(ShowSnackBarEvent)? onShowSnackBar,
    void Function(ShowOverlayEvent)? onShowOverlay,
    void Function(DismissOverlayEvent)? onDismissOverlay,
    void Function(NotifyEvent)? onNotify,
  }) : _bus = bus,
       _navigatorKey = navigatorKey,
       _dialogBuilders = dialogBuilders ?? const {},
       _panelBuilders = panelBuilders ?? const {},
       _onShowSnackBar = onShowSnackBar,
       _onShowOverlay = onShowOverlay,
       _onDismissOverlay = onDismissOverlay,
       _onNotify = onNotify;

  final AppEventBus _bus;
  final GlobalKey<NavigatorState> _navigatorKey;
  final Map<String, DialogBuilder> _dialogBuilders;
  final Map<String, Widget Function(BuildContext, Map<String, Object?>?)>
  _panelBuilders;
  final void Function(ShowSnackBarEvent)? _onShowSnackBar;
  final void Function(ShowOverlayEvent)? _onShowOverlay;
  final void Function(DismissOverlayEvent)? _onDismissOverlay;
  final void Function(NotifyEvent)? _onNotify;

  final List<StreamSubscription> _subscriptions = [];

  /// Start listening to the event bus. Call from StatefulWidget.initState or main.
  void bind() {
    _subscriptions.add(_bus.on<UIActionEvent>().listen(_handleUIAction));
    _subscriptions.add(_bus.on<UISystemEvent>().listen(_handleUISystem));
  }

  /// Stop listening. Call from StatefulWidget.dispose or when tearing down.
  void unbind() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
  }

  void _handleUIAction(UIActionEvent event) {
    final nav = _navigatorKey.currentState;
    if (event is OpenDialogEvent) {
      _openDialog(event, nav);
    } else if (event is ConfirmDialogEvent) {
      _showConfirmDialog(event, nav);
    } else if (event is NavigateToRouteEvent) {
      nav?.pushNamed(event.route, arguments: event.arguments);
    } else if (event is NavigateToShellEvent) {
      _navigateToShell(nav);
    } else if (event is PopNavigationEvent) {
      nav?.pop();
    } else if (event is OpenPauseMenuPanelEvent) {
      _openPauseMenuPanel(event, nav);
    } else if (event is OpenCivilianUnitsPanelEvent) {
      _openCivilianUnitsPanel(event, nav);
    } else if (event is OpenMilitaryUnitsPanelEvent) {
      _openMilitaryUnitsPanel(event, nav);
    } else if (event is OpenNavalUnitsPanelEvent) {
      _openNavalUnitsPanel(event, nav);
    } else if (event is OpenPanelEvent) {
      _openPanel(event, nav);
    } else if (event is ClosePanelEvent) {
      nav?.maybePop();
    }
  }

  void _handleUISystem(UISystemEvent event) {
    if (event is ShowSnackBarEvent) {
      _onShowSnackBar?.call(event);
    } else if (event is ShowOverlayEvent) {
      _onShowOverlay?.call(event);
    } else if (event is DismissOverlayEvent) {
      _onDismissOverlay?.call(event);
    } else if (event is NotifyEvent) {
      _onNotify?.call(event);
    }
  }

  Future<void> _openDialog(OpenDialogEvent event, NavigatorState? nav) async {
    if (nav == null) return;
    final builder = _dialogBuilders[event.dialogId];
    if (builder == null) {
      debugPrint('[AppEventHandler] No dialog builder for: ${event.dialogId}');
      return;
    }
    await showDialog<void>(
      context: nav.context,
      builder: (ctx) => builder(ctx, event.params),
    );
  }

  Future<bool> _showConfirmDialog(
    ConfirmDialogEvent event,
    NavigatorState? nav,
  ) async {
    if (nav == null) {
      event.result(false);
      return false;
    }
    try {
      final result = await showDialog<bool>(
        context: nav.context,
        useRootNavigator: true,
        builder: (ctx) => AlertDialog(
          title: Text(event.title),
          content: Text(event.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(event.cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(event.confirmLabel),
            ),
          ],
        ),
      );
      final confirmed = result ?? false;
      event.result(confirmed);
      return confirmed;
    } catch (e, st) {
      _log.e('ConfirmDialog failed', error: e, stackTrace: st);
      event.result(false);
      return false;
    }
  }

  Future<void> _openPanel(OpenPanelEvent event, NavigatorState? nav) async {
    if (nav == null) return;
    final builder = _panelBuilders[event.panelId];
    if (builder == null) {
      debugPrint('[AppEventHandler] No panel builder for: ${event.panelId}');
      return;
    }
    await showModalBottomSheet<void>(
      context: nav.context,
      builder: (ctx) => builder(ctx, event.params),
    );
  }

  Future<void> _openPauseMenuPanel(
    OpenPauseMenuPanelEvent event,
    NavigatorState? nav,
  ) async {
    if (nav == null) return;
    await showModalBottomSheet<void>(
      context: nav.context,
      builder: (ctx) => PauseMenuPanel(bus: _bus),
    );
  }

  void _navigateToShell(NavigatorState? nav) {
    if (nav == null) return;
    final ctx = nav.context;
    if (ctx.mounted) {
      try {
        final container = ProviderScope.containerOf(ctx, listen: false);
        container.read(currentGameProvider.notifier).clear();
        container.read(currentOrdersProvider.notifier).clear();
      } catch (e, st) {
        _log.d(
          'navigateToShell: skipped in-memory game clear (no ProviderScope)',
          error: e,
          stackTrace: st,
        );
      }
    }
    var foundShellRoute = false;
    nav.popUntil((route) {
      final matches = route.settings.name == Routes.shell;
      if (matches) {
        foundShellRoute = true;
      }
      return matches;
    });
    if (!foundShellRoute) {
      nav.pushNamedAndRemoveUntil(Routes.shell, (route) => false);
    }
  }

  Future<void> _openCivilianUnitsPanel(
    OpenCivilianUnitsPanelEvent event,
    NavigatorState? nav,
  ) async {
    if (nav == null) return;
    await showModalBottomSheet<void>(
      context: nav.context,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final game = ref.watch(currentGameProvider);
          if (game == null) {
            return const SizedBox.shrink();
          }
          final humanPlayerId = _humanPlayerId(game);
          final currentOrders = ref.watch(currentOrdersProvider);
          final availableWorkTargets = ref.watch(availableWorkTargetsProvider);
          final bus = ref.watch(appEventBusProvider);
          final isNarrow =
              MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
          final maxHeight =
              MediaQuery.sizeOf(context).height * (isNarrow ? 0.33 : 0.5);
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: CivilianUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
              bus: bus,
              currentOrders: currentOrders,
              availableWorkTargets: availableWorkTargets,
            ),
          );
        },
      ),
    ).whenComplete(() => _bus.emit(const UnitsPanelClosedEvent('civilian')));
  }

  Future<void> _openMilitaryUnitsPanel(
    OpenMilitaryUnitsPanelEvent event,
    NavigatorState? nav,
  ) async {
    if (nav == null) return;
    await showModalBottomSheet<void>(
      context: nav.context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final game = ref.watch(currentGameProvider);
          if (game == null) {
            return const SizedBox.shrink();
          }
          final humanPlayerId = _humanPlayerId(game);
          final bus = ref.watch(appEventBusProvider);
          final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
          final draftOrders = ref.watch(currentOrdersProvider);
          return MilitaryUnitsPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            bus: bus,
            topology: mapData?.combinedTopology ?? const MapTopology(),
            draftOrders: draftOrders,
          );
        },
      ),
    ).whenComplete(() => _bus.emit(const UnitsPanelClosedEvent('military')));
  }

  Future<void> _openNavalUnitsPanel(
    OpenNavalUnitsPanelEvent event,
    NavigatorState? nav,
  ) async {
    if (nav == null) return;
    await showModalBottomSheet<void>(
      context: nav.context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final game = ref.watch(currentGameProvider);
          if (game == null) {
            return const SizedBox.shrink();
          }
          final humanPlayerId = _humanPlayerId(game);
          final bus = ref.watch(appEventBusProvider);
          final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
          final draftOrders = ref.watch(currentOrdersProvider);
          return NavalUnitsPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            bus: bus,
            topology: mapData?.combinedTopology ?? const MapTopology(),
            draftOrders: draftOrders,
          );
        },
      ),
    ).whenComplete(() => _bus.emit(const UnitsPanelClosedEvent('naval')));
  }

  String _humanPlayerId(Game game) {
    for (final p in game.players) {
      if (p.isHuman) return p.id;
    }
    return game.players.first.id;
  }
}
