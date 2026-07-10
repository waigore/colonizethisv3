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

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../features/game/widgets/shell/shell_player_context.dart';
import '../../../features/game/widgets/shell/shell_player_guarded_body.dart';

import '../../../config/routes.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import '../subscription_tracker.dart';
import '../../../features/game/flame/overlays/exit_confirm_dialog.dart';
import '../../../features/game/widgets/units/civilian/civilian_units_panel.dart';
import '../../../features/game/widgets/units/military/military_units_panel.dart';
import '../../../features/game/widgets/units/naval/naval_units_panel.dart';
import '../../../features/game/widgets/panels/pause_menu_panel.dart';
import '../../../features/game/widgets/units/shared/units_panel_sheet_surface.dart';
import '../../../features/game/widgets/units/shared/units_panel_viewport_constraints.dart';
import '../../../providers/app_event_bus_provider.dart';
import '../../../providers/game_service_provider.dart';
import '../../../providers/games_provider.dart';
import '../../../providers/observe_session_provider.dart';
import '../../../providers/turn_resolution_blocking_provider.dart';
import '../../../widgets/ct_confirm_dialog.dart';

part 'app_event_handler_navigation.dart';
part 'app_event_handler_unit_panels.dart';

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
