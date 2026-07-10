import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler.dart';
import 'package:colonizethis_app/features/shell/save_load/load_game_list_dialog.dart';
import 'package:colonizethis_app/features/shell/save_load/save_game_name_dialog.dart';
import 'package:flutter/material.dart';

/// Feature-layer [OpenDialogEvent] builder for [SaveGameNameDialog].
///
/// Injected via `AppEventHandlerScope.extraDialogBuilders` (Refs #3546).
DialogBuilder buildSaveGameNameDialog(GlobalKey<NavigatorState> navigatorKey) {
  return (ctx, params) => const SaveGameNameDialog();
}

/// Feature-layer [OpenDialogEvent] builder for [LoadGameListDialog].
///
/// Params: `fromPause` (bool) — when true, confirm discard before load.
DialogBuilder buildLoadGameListDialog(GlobalKey<NavigatorState> navigatorKey) {
  return (ctx, params) {
    final fromPause = params?['fromPause'] == true;
    return LoadGameListDialog(fromPause: fromPause);
  };
}
