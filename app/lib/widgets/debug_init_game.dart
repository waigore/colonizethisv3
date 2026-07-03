// Lazy-initialized init game result for Widgetbook and tests.
// SPEC/ui/map-widget.md — debug mode uses map from real map generator and initialized game.

import 'package:colonizethis_logic/colonizethis_logic.dart';

import 'package:colonizethis_app/test_support/seed42_init_game_result.dart';

InitGameResult? _debugInitGameResult;

/// Returns a cached init game result for Widgetbook stories and legacy callers.
///
/// VM/desktop builds load committed seed-42 JSON fixtures (Refs #3656, #3847);
/// web falls back to the procedural generator when fixtures are unavailable.
InitGameResult getDebugInitGameResult() {
  _debugInitGameResult ??= loadSeed42InitGameResult();
  return _debugInitGameResult!;
}
