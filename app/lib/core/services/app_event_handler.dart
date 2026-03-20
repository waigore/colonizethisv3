// AppEventHandler: wires AppEventBus events to actual Navigator / showDialog calls.
// Lives at the shell level; dispatches UIActionEvent and UISystemEvent to Flutter APIs.
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

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

typedef DialogBuilder =
    Widget Function(BuildContext context, Map<String, Object?>? params);

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
    } else if (event is PopNavigationEvent) {
      nav?.pop();
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
    if (nav == null) return false;
    final result = await showDialog<bool>(
      context: nav.context,
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
}
