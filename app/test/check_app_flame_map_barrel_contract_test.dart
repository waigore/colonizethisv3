import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/caches/caches.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/flame/host/host.dart';
import 'package:colonizethis_app/features/game/flame/map_area/map_area.dart';
import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_app/features/game/flame/minimap/minimap.dart';
import 'package:colonizethis_app/features/game/flame/overlays/overlays.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart';
import 'package:colonizethis_app/features/game/flame/render/render.dart';
import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';

/// Barrel export contracts for flame submodules (Refs #3878 Phase 3).
void main() {
  suppressLogsForTests();

  test('map_area barrel exports render background', () {
    expect(GameMapAreaBackground, isNotNull);
  });

  test('map_state barrel exports GameMapArea stack', () {
    expect(GameMapArea, isNotNull);
    expect(GameMapAreaStateLogic, isNotNull);
    expect(GameMapAreaProvinceActionStates, isNotNull);
  });

  test('region_map barrel exports CtRegionMapComponent stack', () {
    expect(CtRegionMapComponent, isNotNull);
    expect(RegionMapViewportSnapshot, isNotNull);
  });

  test('caches barrel exports marker icon caches', () {
    expect(TownIconCache, isNotNull);
    expect(AssetImageCache, isNotNull);
  });

  test('controls barrel exports map shell chrome', () {
    expect(GameMapControls, isNotNull);
    expect(GameSideMenu, isNotNull);
  });

  test('overlays barrel exports session overlays', () {
    expect(VictoryOverlay, isNotNull);
    expect(NextTurnConfirmationDialog, isNotNull);
  });

  test('minimap barrel exports region minimap widget', () {
    expect(GameRegionMinimap, isNotNull);
  });

  test('render barrel exports GP ownership tint constant', () {
    expect(kGpOwnershipTintAlpha, isNotNull);
  });

  test('host barrel exports Flame game host', () {
    expect(ColonizeThisGame, isNotNull);
  });

  test('tilesets barrel exports terrain tileset cache', () {
    expect(TerrainTilesetCache, isNotNull);
  });
}
