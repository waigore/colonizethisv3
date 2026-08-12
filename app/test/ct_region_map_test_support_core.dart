import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' show Player;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/caches/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/town_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map/ct_region_map_game.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtRegionMapComponent;
import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';

import 'map_view_fixture.dart';

/// Shared by `ct_region_map_widget_part*_test.dart` (Refs #4013 / #4021).
CtRegionMapComponent ctRegionMapComponentFromTester(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (w) => w.runtimeType.toString().startsWith('GameWidget<'),
  );
  expect(finder, findsOneWidget);
  final gameWidget = tester.widget(finder);
  final game = (gameWidget as dynamic).game as CtRegionMapGame;
  return game.debugMapComponentForTest;
}

/// Warms Flame caches required before a lone `pump()` in map widget tests.
Future<void> warmCtRegionMapCachesForTests() async {
  await terrainTilesetCache.load();
  await transportOverlayTilesetCache.load();
  await resourceIconCache.load();
  await civilianIconCache.load();
  await townIconCache.load();
  await provinceLabelIconCache.load();
}

/// Minimal view for map tests in [CtMapVisibilityMode.playerConstrained].
const ctRegionMapTestPlayerView = PlayerView(
  playerId: 'ct_region_map_test',
  player: Player(id: 'ct_region_map_test', displayName: 'Test', isHuman: false),
  ownUnitsById: {},
  provincesById: {},
  visibilityByTile: {},
  prospectedTiles: {},
  diplomacyByOtherId: {},
);

// Refs #3656: the committed seed-42 map-view fixture replaces the ~7-11s
// procedural `getDebugInitGameResult()` map generation these helpers previously
// paid once per consuming test isolate. Decoded once and cached for reuse.
InitGameMapViewData? _cachedFixtureMapViewData;

InitGameMapViewData _fixtureMapViewData() =>
    _cachedFixtureMapViewData ??= loadSeed42MapViewData();

RegionMapViewData ctRegionMapTestOldWorldRegion() =>
    _fixtureMapViewData().oldWorld;

RegionMapViewData ctRegionMapTestNewWorldRegion() =>
    _fixtureMapViewData().newWorld;
