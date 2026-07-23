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

import '../subscription_tracker.dart';
import '../../../providers/turn_resolution_blocking_provider.dart';
import 'app_event_handler_navigation.dart';
import 'app_event_handler_unit_panels.dart';

typedef DialogBuilder =
    Widget Function(BuildContext context, Map<String, Object?>? params);

/// Factory for a feature-layer [DialogBuilder] that needs the app navigator
/// key. The composition root injects the factory (a const top-level tear-off)
/// without holding the global `appNavigatorKey`; the core scope resolves it
/// with the navigator key so feature layers thread the key explicitly instead
/// of reaching for the global (Refs #3546). SPEC/program/app-ui-wiring.md.
typedef NavigatorKeyDialogBuilder =
    DialogBuilder Function(GlobalKey<NavigatorState> navigatorKey);

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
        openDialog(event, nav);
      case ConfirmDialogEvent():
        showConfirmDialog(event, nav);
      case NavigateToRouteEvent():
        nav?.pushNamed(event.route, arguments: event.arguments);
      case NavigateToShellEvent():
        navigateToShell(nav);
      case PopNavigationEvent():
        nav?.pop();
      case RequestExitToMainMenuFlowEvent():
        handleRequestExitToMainMenuFlow(nav);
      case OpenPauseMenuPanelEvent():
        openPauseMenuPanel(event, nav);
      case OpenCivilianUnitsPanelEvent():
        openCivilianUnitsPanel(event, nav);
      case OpenMilitaryUnitsPanelEvent():
        openMilitaryUnitsPanel(event, nav);
      case OpenNavalUnitsPanelEvent():
        openNavalUnitsPanel(event, nav);
      case OpenPanelEvent():
        openPanel(event, nav);
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

  // Package-internal accessors for de-parted extension libraries (Refs #4117).
  AppEventBus get handlerBus => _bus;

  GlobalKey<NavigatorState> get handlerNavigatorKey => _navigatorKey;

  Map<String, DialogBuilder> get handlerDialogBuilders => _dialogBuilders;

  Map<String, Widget Function(BuildContext, Map<String, Object?>?)>
  get handlerPanelBuilders => _panelBuilders;

  void Function(ShowSnackBarEvent)? get handlerOnShowSnackBar =>
      _onShowSnackBar;

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
