// Shared owned-province overlay pump for MAP20001 widget pins (Refs #4642).

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay, demoRegionForOverlay;
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, ProvinceImprovableCommodityCount, buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_test_harness.dart';

/// Pumps an owned Old World province overlay from [demoGameForOverlay].
///
/// Does not force [omniscientDetail] or [extractionSnapshot]; callers that
/// omit them keep the [pumpProvinceOverlayAtDarkTheme] defaults.
Future<void> pumpOwnedProvinceOverlayAtDarkTheme(
  WidgetTester tester, {
  Game? game,
  String? displayId,
  String? humanPlayerId,
  PlayerView? playerView,
  RegionMapViewData? region,
  bool omniscientDetail = false,
  ProvinceExtractionSnapshot? extractionSnapshot,
  Map<String, ProvinceImprovableCommodityCount> availableByCommodity = const {},
  Map<String, int> townProductionBonusByCommodity = const {},
  void Function(Iterable<String>? tileKeys)? onHighlightTiles,
  double? shellWidth,
}) async {
  final resolvedGame = game ?? demoGameForOverlay;
  final resolvedHuman = humanPlayerId ?? resolvedGame.players.first.id;
  final resolvedDisplay =
      displayId ??
      ownedProvinceIdInOldWorld(game: resolvedGame, ownerId: resolvedHuman);
  await pumpProvinceOverlayAtDarkTheme(
    tester,
    game: resolvedGame,
    displayId: resolvedDisplay,
    region: region ?? demoRegionForOverlay,
    humanPlayerId: resolvedHuman,
    playerView:
        playerView ??
        buildPlayerView(resolvedGame, const MapTopology(), resolvedHuman),
    omniscientDetail: omniscientDetail,
    extractionSnapshot: extractionSnapshot,
    availableByCommodity: availableByCommodity,
    townProductionBonusByCommodity: townProductionBonusByCommodity,
    onHighlightTiles: onHighlightTiles,
    shellWidth: shellWidth,
  );
}
