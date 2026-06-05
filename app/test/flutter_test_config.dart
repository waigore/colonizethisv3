import 'dart:async';

import 'package:colonizethis_app/config/map_terrain_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ensures asset bundle and [MapTerrainConfig] are ready for any test that
/// touches [mapViewDataProvider] or [terrainTilesetCache] without going through
/// [WidgetTester.pumpWidget].
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Tests run offline; disable runtime font fetching as a defense-in-depth
  // measure so any incidental `GoogleFonts.<family>()` call surfaces a
  // missing-asset exception instead of attempting an HTTP download against
  // `fonts.gstatic.com`. Production mirrors this in `main()` and registers
  // bundled Cinzel via `preloadEditorialMonocleFonts` before `runApp`.
  GoogleFonts.config.allowRuntimeFetching = false;
  await MapTerrainConfig.ensureLoaded();
  await testMain();
}
