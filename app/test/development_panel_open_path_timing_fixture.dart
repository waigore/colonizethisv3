// Campaign-sized fixture for GAME80001 session-cache reopen timing (Refs #4687).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show PlayerView, buildPlayerView;

import 'development_panel_test_support.dart';
import 'panel_fixtures/core.dart';

class DevelopmentPanelOpenPathTimingFixture {
  DevelopmentPanelOpenPathTimingFixture._({
    required this.game,
    required this.humanPlayerId,
    required this.mapData,
    required this.playerView,
  });

  final Game game;
  final String humanPlayerId;
  final ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    List<WarpLink>? warpLinks,
  })
  mapData;
  final PlayerView playerView;

  factory DevelopmentPanelOpenPathTimingFixture.build() {
    final game = buildDevelopmentPanelGoldenGame();
    final mapData = DevelopmentPanelMapGameService.goldenMapData();
    final humanPlayerId = kPanelTestHumanPlayerId;
    final playerView = buildPlayerView(
      game,
      mapData.combinedTopology,
      humanPlayerId,
    );
    return DevelopmentPanelOpenPathTimingFixture._(
      game: game,
      humanPlayerId: humanPlayerId,
      mapData: mapData,
      playerView: playerView,
    );
  }
}

int developmentPanelOpenPathTimeMicros(
  void Function() fn, {
  required int iterations,
}) {
  for (var i = 0; i < 3; i++) {
    fn();
  }
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    fn();
  }
  sw.stop();
  return sw.elapsedMicroseconds ~/ iterations;
}

int developmentPanelOpenPathTimeMicrosMedian(
  void Function() fn, {
  required int iterations,
}) {
  final samples = <int>[
    for (var run = 0; run < 3; run++)
      developmentPanelOpenPathTimeMicros(fn, iterations: iterations),
  ]..sort();
  return samples[1];
}
