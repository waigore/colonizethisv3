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
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/editorial_monocle_palette.dart';
import '../../features/game/shell_player_context.dart';
import '../../features/game/widgets/observe_mode_not_defined_panel.dart';

import '../../config/routes.dart';
import '../../config/constants.dart';
import '../../config/ct_e2e.dart';
import '../../config/ct_e2e_last_panel_snapshot.dart';
import 'subscription_tracker.dart';
import '../../features/game/flame/exit_confirm_dialog.dart';
import '../../features/game/widgets/civilian_units_panel.dart';
import '../../features/game/widgets/military_units_panel.dart';
import '../../features/game/widgets/naval_units_panel.dart';
import '../../features/game/widgets/pause_menu_panel.dart';
import '../../providers/app_event_bus_provider.dart';
import '../../providers/game_service_provider.dart';
import '../../providers/games_provider.dart';
import '../../providers/observe_session_provider.dart';
import '../../providers/turn_resolution_blocking_provider.dart';

typedef DialogBuilder =
    Widget Function(BuildContext context, Map<String, Object?>? params);

final _log = packageLogger('event');

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

  final SubscriptionTracker _subscriptions = SubscriptionTracker();

  /// Start listening to the event bus. Call from StatefulWidget.initState or main.
  void bind() {
    _subscriptions.track(_bus.on<UIActionEvent>().listen(_handleUIAction));
    _subscriptions.track(_bus.on<UISystemEvent>().listen(_handleUISystem));
  }

  /// Stop listening. Call from StatefulWidget.dispose or when tearing down.
  void unbind() {
    _subscriptions.cancelAll();
  }

  void _handleUIAction(UIActionEvent event) {
    if (event is LocateMapTileEvent) {
      return;
    }
    final nav = _navigatorKey.currentState;
    if (_shouldBlockUiActionDuringTurnResolution(nav, event)) {
      _log.d(
        'logic: blocked ${event.runtimeType} during active turn resolution',
      );
      return;
    }
    switch (event) {
      case OpenDialogEvent():
        _openDialog(event, nav);
      case ConfirmDialogEvent():
        _showConfirmDialog(event, nav);
      case NavigateToRouteEvent():
        nav?.pushNamed(event.route, arguments: event.arguments);
      case NavigateToShellEvent():
        _navigateToShell(nav);
      case PopNavigationEvent():
        nav?.pop();
      case RequestExitToMainMenuFlowEvent():
        _handleRequestExitToMainMenuFlow(nav);
      case OpenPauseMenuPanelEvent():
        _openPauseMenuPanel(event, nav);
      case OpenCivilianUnitsPanelEvent():
        _openCivilianUnitsPanel(event, nav);
      case OpenMilitaryUnitsPanelEvent():
        _openMilitaryUnitsPanel(event, nav);
      case OpenNavalUnitsPanelEvent():
        _openNavalUnitsPanel(event, nav);
      case OpenPanelEvent():
        _openPanel(event, nav);
      case ClosePanelEvent():
        nav?.maybePop();
      case _:
        return;
    }
  }

  void _handleUISystem(UISystemEvent event) {
    switch (event) {
      case ShowSnackBarEvent():
        _onShowSnackBar?.call(event);
      case ShowOverlayEvent():
        _onShowOverlay?.call(event);
      case DismissOverlayEvent():
        _onDismissOverlay?.call(event);
      case NotifyEvent():
        _onNotify?.call(event);
    }
  }

  static const _observeBlockedDialogIds = {
    'train_civilians',
    'train_military',
    'grant_or_subsidy',
  };

  Future<void> _openDialog(OpenDialogEvent event, NavigatorState? nav) async {
    if (nav == null) return;
    if (_observeBlockedDialogIds.contains(event.dialogId)) {
      final ctx = nav.context;
      final container = ProviderScope.containerOf(ctx);
      if (!container.read(shellPlayerContextProvider).canMutateViaUi) {
        _onShowSnackBar?.call(
          const ShowSnackBarEvent(
            message: 'Observe mode: UI actions are read-only.',
          ),
        );
        return;
      }
    }
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
    await showDialog<void>(
      context: nav.context,
      useRootNavigator: true,
      barrierColor: EditorialMonoclePalette.dialogScrim,
      builder: (ctx) => PauseMenuPanel(bus: _bus),
    );
  }

  /// Pause-menu Exit to Main Menu flow. The pause sheet has already emitted
  /// [ClosePanelEvent] before this event fires, so the sheet is being
  /// dismissed via `Navigator.maybePop`. We schedule the exit-confirm
  /// dialog after the current frame so the closing pop completes before
  /// the new modal mounts (preventing the confirm dialog from being torn
  /// down with the pause sheet). SPEC: `SPEC/ui/pause-menu-panel.md`
  /// § Navigation, `SPEC/ui/in-game-shell-narrow.md` § Android back confirm.
  void _handleRequestExitToMainMenuFlow(NavigatorState? nav) {
    if (nav == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = _navigatorKey.currentState;
      final ctx = state?.context;
      if (state == null || ctx == null || !ctx.mounted) return;
      final confirmed = await showExitToMainMenuConfirmDialog(ctx);
      if (!confirmed) return;
      _bus.emit(const NavigateToShellEvent());
    });
  }

  void _navigateToShell(NavigatorState? nav) {
    if (nav == null) return;
    final ctx = nav.context;
    if (ctx.mounted) {
      try {
        final container = ProviderScope.containerOf(ctx, listen: false);
        container.read(currentGameProvider.notifier).clear();
        container.read(currentOrdersProvider.notifier).clear();
        container.read(observeSessionProvider.notifier).reset();
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
          final shell = ref.read(shellPlayerContextProvider);
          final civilianOwnerIds = resolveCivilianMarkerOwnerIds(shell, game);
          final panelPlayerId = shellPanelPlayerId(ref, game);
          final readOnly = !shell.canMutateViaUi;
          final currentOrders = ref.watch(currentOrdersProvider);
          final bus = ref.watch(appEventBusProvider);
          final isNarrow = MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
          final maxHeight =
              MediaQuery.sizeOf(context).height * (isNarrow ? 0.33 : 0.5);
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: CivilianUnitsPanel(
              game: game,
              humanPlayerId:
                  panelPlayerId ??
                  (civilianOwnerIds.isNotEmpty
                      ? civilianOwnerIds.first
                      : game.players.first.id),
              civilianOwnerIds: civilianOwnerIds,
              bus: bus,
              readOnly: readOnly,
              currentOrders: currentOrders,
              tileScopeTileKey: event.tileScopeTileKey,
              initialSelectedUnitId: event.initialSelectedUnitId,
              explorerOnly: event.explorerOnly,
              builderOnly: event.builderOnly,
              prospectShortcutTargetTileKey:
                  event.prospectShortcutTargetTileKey,
              exploreShortcutTargetTileKey: event.exploreShortcutTargetTileKey,
              buildImprovementShortcutTargetTileKey:
                  event.buildImprovementShortcutTargetTileKey,
            ),
          );
        },
      ),
    ).whenComplete(() {
      if (kCtE2EEnabled) {
        updateCtE2eCivilianPanelSnapshotIfEnabled(null);
      }
      _bus.emit(const UnitsPanelClosedEvent('civilian'));
    });
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
          if (shellPanelsNotDefined(ref)) {
            return const ObserveModeNotDefinedPanel(title: 'Military Units');
          }
          final humanPlayerId = shellPanelPlayerId(ref, game);
          final readOnly =
              !ref.read(shellPlayerContextProvider).canMutateViaUi;
          final bus = ref.watch(appEventBusProvider);
          final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
          final draftOrders = ref.watch(currentOrdersProvider);
          return MilitaryUnitsPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            bus: bus,
            readOnly: readOnly,
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
          if (shellPanelsNotDefined(ref)) {
            return const ObserveModeNotDefinedPanel(title: 'Naval Units');
          }
          final humanPlayerId = shellPanelPlayerId(ref, game);
          final readOnly =
              !ref.read(shellPlayerContextProvider).canMutateViaUi;
          final bus = ref.watch(appEventBusProvider);
          final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
          final draftOrders = ref.watch(currentOrdersProvider);
          return NavalUnitsPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            bus: bus,
            readOnly: readOnly,
            topology: mapData?.combinedTopology ?? const MapTopology(),
            draftOrders: draftOrders,
            tileMapByRegion: mapData?.tileMapByRegion,
            topologyByRegion: mapData?.topologyByRegion,
            locationScopeKey: event.locationScopeKey,
            initialSelectedFleetId: event.initialSelectedFleetId,
            tileScopeTileKey: event.tileScopeTileKey,
          );
        },
      ),
    ).whenComplete(() {
      // Keep the last naval snapshot after close; [refreshCtE2eNavalPanelSnapshotAfterTurnIfEnabled]
      // updates it post–next-turn so fleet E2E can skip reopening the panel (Refs #2336).
      _bus.emit(const UnitsPanelClosedEvent('naval'));
    });
  }

  /// While turn resolution blocks UI bus actions, pause menu remains reachable (#2160).
  bool _shouldBlockUiActionDuringTurnResolution(
    NavigatorState? nav,
    UIActionEvent event,
  ) {
    // Pause sheet open/close must stay reachable while resolving (#2160).
    if (event is OpenPauseMenuPanelEvent || event is ClosePanelEvent) {
      return false;
    }
    final ctx = nav?.context;
    if (ctx == null || !ctx.mounted) return false;
    try {
      return ProviderScope.containerOf(
        ctx,
        listen: false,
      ).read(turnResolutionBlockingProvider);
    } catch (_) {
      return false;
    }
  }
}
