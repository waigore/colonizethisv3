// Debug Marionette binding for agent playtesting (Refs #4199 WS1).

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'colonizethis_marionette_configuration.dart';

/// Whether [MarionetteBinding] should replace [WidgetsFlutterBinding] in this
/// process. Debug agent playtests only — never under `flutter test`,
/// `integration_test`, or CT_E2E builds (single-binding rule).
@visibleForTesting
bool marionetteBindingEnabled({
  required bool debugMode,
  required bool flutterTest,
  required bool ctE2eEnabled,
}) {
  return debugMode && !flutterTest && !ctE2eEnabled;
}

/// Initializes the app Flutter binding for production [main] entrypoints.
void ensureColonizeThisAppBinding() {
  if (marionetteBindingEnabled(
    debugMode: kDebugMode,
    flutterTest: const bool.fromEnvironment('FLUTTER_TEST'),
    ctE2eEnabled: kCtE2EEnabled,
  )) {
    MarionetteBinding.ensureInitialized(colonizethisMarionetteConfiguration);
    return;
  }
  WidgetsFlutterBinding.ensureInitialized();
}
