// Shared editorial-monocle pump shell for ProvinceSeaZoneDetailOverlay dark-token
// pins. Refs #3847.

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';

/// Returns a province id (`regionId|localId`) owned by [ownerId] in the demo
/// Old World. Province ids in the debug-init game are already prefixed.
String ownedProvinceIdInOldWorld({
  required Game game,
  required String ownerId,
}) {
  for (final province in game.worldState.oldWorld.provinces) {
    if (province.ownerId == ownerId) {
      return province.id;
    }
  }
  fail(
    'Test setup: no province in oldWorld is owned by "$ownerId"; '
    'cannot construct a human-owned province for overlay pins.',
  );
}

/// Builds a [MaterialApp] shell mounting [ProvinceSeaZoneDetailOverlay] under
/// `AppThemes.editorialMonocle` for dark-token widget tests.
Widget buildProvinceOverlayDarkThemeShell({
  required Game game,
  required String displayId,
  RegionMapViewData? region,
  String? selectedTileKey,
  String? humanPlayerId,
  PlayerView? playerView,
  Orders draftOrders = const Orders(),
  double? shellWidth,
}) {
  final overlay = ProvinceSeaZoneDetailOverlay(
    game: game,
    region: region ?? demoRegionForOverlay,
    displayId: displayId,
    selectedTileKey: selectedTileKey,
    humanPlayerId: humanPlayerId ?? game.players.first.id,
    playerView: playerView ?? demoHumanPlayerViewForOverlay,
    draftOrders: draftOrders,
  );
  final body = shellWidth != null
      ? SizedBox(width: shellWidth, child: overlay)
      : overlay;
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(body: body),
  );
}

/// Pumps [buildProvinceOverlayDarkThemeShell] and flushes the first layout pass.
Future<void> pumpProvinceOverlayAtDarkTheme(
  WidgetTester tester, {
  required Game game,
  required String displayId,
  RegionMapViewData? region,
  String? selectedTileKey,
  String? humanPlayerId,
  PlayerView? playerView,
  Orders draftOrders = const Orders(),
  double? shellWidth,
}) async {
  await tester.pumpWidget(
    buildProvinceOverlayDarkThemeShell(
      game: game,
      displayId: displayId,
      region: region,
      selectedTileKey: selectedTileKey,
      humanPlayerId: humanPlayerId,
      playerView: playerView,
      draftOrders: draftOrders,
      shellWidth: shellWidth,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}
