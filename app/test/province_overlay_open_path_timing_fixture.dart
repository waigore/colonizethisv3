// Campaign-sized fixture for MAP20001 open-path timing guards (Refs #4690 Slice C).

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay, sampleProvinceIdForOverlay;
import 'package:colonizethis_app_fixtures/test_support/seed42_tile_map_loader.dart'
    show loadSeed42TileMapByRegion;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'map_view_fixture.dart';

class ProvinceOverlayOpenPathTimingFixture {
  ProvinceOverlayOpenPathTimingFixture._({
    required this.game,
    required this.displayId,
    required this.mapData,
  });

  final Game game;
  final String displayId;
  final GameMapData mapData;

  factory ProvinceOverlayOpenPathTimingFixture.build() {
    final mapView = loadSeed42MapViewData();
    return ProvinceOverlayOpenPathTimingFixture._(
      game: demoGameForOverlay,
      displayId: sampleProvinceIdForOverlay,
      mapData: (
        combinedTopology: mapView.combinedTopology,
        tileMapByRegion: loadSeed42TileMapByRegion(),
        topologyByRegion: const {},
        warpLinks: null,
      ),
    );
  }
}

int provinceOverlayOpenPathTimeMicros(
  void Function() fn, {
  required int iterations,
}) {
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    fn();
  }
  sw.stop();
  return sw.elapsedMicroseconds ~/ iterations;
}

int provinceOverlayOpenPathTimeMicrosMedian(
  void Function() fn, {
  required int iterations,
}) {
  final samples = <int>[
    for (var run = 0; run < 3; run++)
      provinceOverlayOpenPathTimeMicros(fn, iterations: iterations),
  ]..sort();
  return samples[1];
}
