import 'package:flutter/material.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

typedef DialogBuilder =
    Widget Function(BuildContext context, Map<String, Object?>? params);

/// Factory for a feature-layer [DialogBuilder] that needs the app navigator
/// key. The composition root injects the factory (a const top-level tear-off)
/// without holding the global `appNavigatorKey`; the core scope resolves it
/// with the navigator key so feature layers thread the key explicitly instead
/// of reaching for the global (Refs #3546). SPEC/program/app-ui-wiring.md.
typedef NavigatorKeyDialogBuilder =
    DialogBuilder Function(GlobalKey<NavigatorState> navigatorKey);

/// Mutable session fields shared by de-parted [AppEventHandler] implementation
/// libraries (Refs #4117).
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
  });

  final AppEventBus bus;
  final GlobalKey<NavigatorState> navigatorKey;
  final Map<String, DialogBuilder> dialogBuilders;
  final Map<String, Widget Function(BuildContext, Map<String, Object?>?)>
      panelBuilders;
  final void Function(ShowSnackBarEvent)? onShowSnackBar;
  final void Function(ShowOverlayEvent)? onShowOverlay;
  final void Function(DismissOverlayEvent)? onDismissOverlay;
  final void Function(NotifyEvent)? onNotify;
}
