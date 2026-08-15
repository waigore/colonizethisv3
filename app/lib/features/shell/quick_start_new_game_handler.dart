import 'dart:async';

import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_app/features/shell/new_game_setup_flow.dart';
import 'package:colonizethis_app/features/shell/new_game_setup_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logShell = packageLogger('shell');

/// Composition-root handler for [QuickStartNewGameEvent].
///
/// Threads [navigatorKey] explicitly; does not read `appNavigatorKey`.
/// Refs #4416. SPEC/program/app-ui-wiring.md.
void handleQuickStartNewGame(GlobalKey<NavigatorState> navigatorKey) {
  final navCtx = navigatorKey.currentContext;
  if (navCtx == null) {
    _logShell.w('navigator key has no context; skipping quick start');
    return;
  }
  final container = ProviderScope.containerOf(navCtx);
  unawaited(
    runNewGameSetupAfterLeaderPick(
      navigatorKey: navigatorKey,
      container: container,
      templateConfig: quickStartSetupConfig(),
    ),
  );
}
