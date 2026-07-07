// Web fallback for seed-42 fixture loaders when committed JSON is unavailable.
//
// Widgetbook/web builds cannot read `app/test/support/fixtures/` from disk;
// fall back to the cached procedural generator until fixtures are bundled.

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app_fixtures/debug_init_game.dart';

/// Decodes seed-42 [Game] data; on web uses [getDebugInitGameResult].
Game loadSeed42Game() => getDebugInitGameResult().game;

/// Decodes seed-42 map-view data; on web uses [getDebugInitGameResult].
InitGameMapViewData loadSeed42MapViewData() =>
    getDebugInitGameResult().mapViewData;
