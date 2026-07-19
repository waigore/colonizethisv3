import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler.dart';
import 'package:colonizethis_app/features/shell/settings/settings_dialog.dart';
import 'package:flutter/material.dart';

/// Feature-layer [OpenDialogEvent] builder for [SettingsDialog].
///
/// Injected via `AppEventHandlerScope.extraDialogBuilders` (Refs #3546).
DialogBuilder buildSettingsDialog(GlobalKey<NavigatorState> navigatorKey) {
  return (ctx, params) => const SettingsDialog();
}
