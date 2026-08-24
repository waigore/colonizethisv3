// Fixtures for province overlay extraction/available pins (Refs #4352).

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show ProvinceImprovableCommodityCount;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

Game demoGameForOwnedPump() => demoGameForOverlay;

String demoOverlayHumanId() => demoGameForOverlay.players.first.id;

String foreignOwnedProvinceIdForOverlay({
  required Game game,
  required String humanPlayerId,
}) {
  for (final province in game.worldState.oldWorld.provinces) {
    final ownerId = province.ownerId;
    if (ownerId != null && ownerId.isNotEmpty && ownerId != humanPlayerId) {
      return province.id;
    }
  }
  fail(
    'Test setup: demo game has no foreign-owned Old World province for '
    'intel-gate pins.',
  );
}

ProvinceExtractionSnapshot sampleProvinceExtractionSnapshot(
  String ownerId, {
  int capitalGrainBonus = 0,
}) {
  return ProvinceExtractionSnapshot(
    ownerId: ownerId,
    capitalGrainBonus: capitalGrainBonus,
    byCommodity: {
      'grain': const ProvinceExtractionCommodityTotals(
        effective: 1,
        full: 5,
        tileKeys: ['oldWorld|p1|0|0', 'oldWorld|p1|0|1'],
      ),
      'iron': const ProvinceExtractionCommodityTotals(
        effective: 5,
        full: 5,
        tileKeys: ['oldWorld|p1|1|0'],
      ),
    },
  );
}

const Map<String, ProvinceImprovableCommodityCount>
sampleProvinceImprovableAvailable = {
  'grain': ProvinceImprovableCommodityCount(
    count: 3,
    tileKeys: ['oldWorld|p1|0|0', 'oldWorld|p1|2|0'],
  ),
  'timber': ProvinceImprovableCommodityCount(
    count: 2,
    tileKeys: ['oldWorld|p1|0|1'],
  ),
};
