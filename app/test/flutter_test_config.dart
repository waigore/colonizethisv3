import 'dart:async';

import 'package:colonizethis_app/config/map_terrain_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ensures asset bundle and [MapTerrainConfig] are ready for any test that
/// touches [mapViewDataProvider] or [terrainTilesetCache] without going through
/// [WidgetTester.pumpWidget].
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await MapTerrainConfig.ensureLoaded();
  await testMain();
}
