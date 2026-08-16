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

import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/turn_resolution_blocking_provider.dart';
import '../subscription_tracker.dart';
import 'app_event_handler_navigation.dart';
import 'app_event_handler_unit_marker_flows.dart';
import 'app_event_handler_unit_panels.dart';

typedef DialogBuilder =
    Widget Function(BuildContext context, Map<String, Object?>? params);

/// Factory for a feature-layer [DialogBuilder] that needs the app navigator
/// key.
typedef NavigatorKeyDialogBuilder =
    DialogBuilder Function(GlobalKey<NavigatorState> navigatorKey);

/// Feature-layer [UIActionEvent] handler that needs the app navigator key.
///
/// Injected at the composition root via
/// [AppEventHandlerScope.extraActionHandlers] so `core/services/` does not
/// import `features/shell/`. Refs #4416.
typedef NavigatorKeyActionHandler =
    void Function(GlobalKey<NavigatorState> navigatorKey);

/// Mutable session fields shared by de-parted [AppEventHandler] libraries.
class AppEventHandlerState {
  AppEventHandlerState({
    required this.bus,
    required this.navigatorKey,
    required this.dialogBuilders,
    required this.panelBuilders,
    this.onShowSnackBar,
    this.onShowOverlay,
    this.onDismissOverlay,
    this.onNotify,
    this.extraActionHandlers = const {},
  });

  final AppEventBus bus;
  final GlobalKey<NavigatorState> navigatorKey;
  final Map<String, DialogBuilder> dialogBuilders;
  final Map<String, Widget Function(BuildContext, Map<String, Object?>?)>
  panelBuilders;
  final Map<Type, NavigatorKeyActionHandler> extraActionHandlers;
  final void Function(ShowSnackBarEvent)? onShowSnackBar;
  final void Function(ShowOverlayEvent)? onShowOverlay;
  final void Function(DismissOverlayEvent)? onDismissOverlay;
  final void Function(NotifyEvent)? onNotify;
}

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
    Map<Type, NavigatorKeyActionHandler>? extraActionHandlers,
  }) : state = AppEventHandlerState(
         bus: bus,
         navigatorKey: navigatorKey,
         dialogBuilders: dialogBuilders ?? const {},
         panelBuilders: panelBuilders ?? const {},
         onShowSnackBar: onShowSnackBar,
         onShowOverlay: onShowOverlay,
         onDismissOverlay: onDismissOverlay,
         onNotify: onNotify,
         extraActionHandlers: extraActionHandlers ?? const {},
       );

  /// Session fields shared by de-parted implementation libraries (Refs #4117).
  final AppEventHandlerState state;

  final SubscriptionTracker _subscriptions = SubscriptionTracker();

  /// Start listening to the event bus. Call from StatefulWidget.initState or main.
  void bind() {
    _subscriptions.track(state.bus.on<UIActionEvent>().listen(_handleUIAction));
    _subscriptions.track(state.bus.on<UISystemEvent>().listen(_handleUISystem));
  }

  /// Stop listening. Call from StatefulWidget.dispose or when tearing down.
  void unbind() {
    _subscriptions.cancelAll();
  }

  void _handleUIAction(UIActionEvent event) {
    if (event is LocateMapTileEvent) {
      return;
    }
    final nav = state.navigatorKey.currentState;
    if (_shouldBlockUiActionDuringTurnResolution(nav, event)) {
      _log.d(
        'logic: blocked ${event.runtimeType} during active turn resolution',
      );
      return;
    }
    switch (event) {
      case OpenDialogEvent():
        appEventHandlerOpenDialog(this, event, nav);
      case ConfirmDialogEvent():
        appEventHandlerShowConfirmDialog(this, event, nav);
      case DevelopmentDisconnectedAssignDialogEvent():
        appEventHandlerShowDevelopmentDisconnectedAssignDialog(
          this,
          event,
          nav,
        );
      case NavigateToRouteEvent():
        nav?.pushNamed(event.route, arguments: event.arguments);
      case NavigateToShellEvent():
        appEventHandlerNavigateToShell(this, nav);
      case PopNavigationEvent():
        nav?.pop();
      case RequestExitToMainMenuFlowEvent():
        appEventHandlerRequestExitToMainMenuFlow(this, nav);
      case OpenPauseMenuPanelEvent():
        appEventHandlerOpenPauseMenuPanel(this, event, nav);
      case OpenCivilianUnitsPanelEvent():
        appEventHandlerOpenCivilianUnitsPanel(this, event, nav);
      case OpenMilitaryUnitsPanelEvent():
        appEventHandlerOpenMilitaryUnitsPanel(this, event, nav);
      case OpenNavalUnitsPanelEvent():
        appEventHandlerOpenNavalUnitsPanel(this, event, nav);
      case OpenNavalMissionMenuEvent():
        appEventHandlerOpenNavalMissionMenu(this, event, nav);
      case OpenArmyStackMarkerEvent():
        appEventHandlerOpenArmyStackMarker(this, event, nav);
      case OpenPanelEvent():
        appEventHandlerOpenPanel(this, event, nav);
      case ClosePanelEvent():
        nav?.maybePop();
      case _:
        state.extraActionHandlers[event.runtimeType]?.call(state.navigatorKey);
    }
  }

  void _handleUISystem(UISystemEvent event) {
    switch (event) {
      case ShowSnackBarEvent():
        state.onShowSnackBar?.call(event);
      case ShowOverlayEvent():
        state.onShowOverlay?.call(event);
      case DismissOverlayEvent():
        state.onDismissOverlay?.call(event);
      case NotifyEvent():
        state.onNotify?.call(event);
    }
  }

  /// While turn resolution blocks UI bus actions, pause open is suppressed (#3989).
  bool _shouldBlockUiActionDuringTurnResolution(
    NavigatorState? nav,
    UIActionEvent event,
  ) {
    // Allow dismissing an already-open panel; do not open pause mid-resolve.
    if (event is ClosePanelEvent) {
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
