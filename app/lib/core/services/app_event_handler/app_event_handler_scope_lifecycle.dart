import 'dart:async';

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:flutter/material.dart';

import 'app_event_handler.dart';
import 'app_event_handler_scope_dialog_builders.dart';
import 'app_event_handler_scope_log.dart';
import 'app_event_handler_scope_session_helpers.dart';
import 'app_event_handler_scope_session_subscriptions.dart';

/// Binds [AppEventHandler] once and tears down session listeners on dispose.
mixin AppEventHandlerScopeLifecycle
    on
        AppEventHandlerScopeSessionHelpers,
        AppEventHandlerScopeDialogBuilders,
        AppEventHandlerScopeSessionCommands {
  AppEventHandler? handler;
  var bound = false;
  final List<StreamSubscription<dynamic>> sessionCommandSubs = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (bound) {
      return;
    }
    bound = true;
    final bus = ref.read(appEventBusProvider);
    handler = AppEventHandler(
      bus: bus,
      navigatorKey: appNavigatorKey,
      dialogBuilders: dialogBuilders(),
      onShowSnackBar: showSnackBarForEvent,
    );
    handler!.bind();
    sessionCommandSubs.addAll(sessionCommandListeners(bus));
    appEventHandlerScopeLog.d(
      'AppEventHandler bound; session command listeners attached',
    );
  }

  @override
  void dispose() {
    for (final s in sessionCommandSubs) {
      s.cancel();
    }
    sessionCommandSubs.clear();
    handler?.unbind();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
