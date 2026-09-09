// Sole-cause Train {type} helper pins (Refs #4752).

import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_catalog.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/map_train_civilian_offer.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  test('offers Train only when no matching units is the sole disablement', () {
    expect(
      offerMapTrainCivilian(
        showIcon: true,
        hasMatchingUnits: false,
        otherNonUnitGateApplies: false,
        trainTapAvailable: true,
      ),
      isTrue,
    );
  });

  test('omits Train when matching units exist', () {
    expect(
      offerMapTrainCivilian(
        showIcon: true,
        hasMatchingUnits: true,
        otherNonUnitGateApplies: false,
        trainTapAvailable: true,
      ),
      isFalse,
    );
  });

  test('omits Train when a Consulate or other non-unit gate also applies', () {
    expect(
      offerMapTrainCivilian(
        showIcon: true,
        hasMatchingUnits: false,
        otherNonUnitGateApplies: true,
        trainTapAvailable: true,
      ),
      isFalse,
    );
  });

  test('omits Train when the shortcut is hidden or tap is unavailable', () {
    expect(
      offerMapTrainCivilian(
        showIcon: false,
        hasMatchingUnits: false,
        otherNonUnitGateApplies: false,
        trainTapAvailable: true,
      ),
      isFalse,
    );
    expect(
      offerMapTrainCivilian(
        showIcon: true,
        hasMatchingUnits: false,
        otherNonUnitGateApplies: false,
        trainTapAvailable: false,
      ),
      isFalse,
    );
  });

  test('maps radial catalog actions to hire kinds', () {
    expect(
      mapTrainCivilianKindForRadialAction(TileRadialCatalogAction.explore),
      MapTrainCivilianKind.explorer,
    );
    expect(
      mapTrainCivilianKindForRadialAction(TileRadialCatalogAction.prospect),
      MapTrainCivilianKind.explorer,
    );
    expect(
      mapTrainCivilianKindForRadialAction(
        TileRadialCatalogAction.buildImprovement,
      ),
      MapTrainCivilianKind.builder,
    );
    expect(
      mapTrainCivilianKindForRadialAction(TileRadialCatalogAction.upgradeTown),
      MapTrainCivilianKind.builder,
    );
    expect(
      mapTrainCivilianKindForRadialAction(TileRadialCatalogAction.buildRoad),
      MapTrainCivilianKind.engineer,
    );
    expect(
      mapTrainCivilianKindForRadialAction(TileRadialCatalogAction.purchaseLand),
      MapTrainCivilianKind.merchant,
    );
    expect(
      mapTrainCivilianKindForRadialAction(TileRadialCatalogAction.buildRail),
      MapTrainCivilianKind.railBuilder,
    );
    expect(
      mapTrainCivilianKindForRadialAction(TileRadialCatalogAction.buildPort),
      MapTrainCivilianKind.engineer,
    );
    expect(
      mapTrainCivilianKindForRadialAction(TileRadialCatalogAction.buildFort),
      MapTrainCivilianKind.engineer,
    );
    for (final action in TileRadialCatalogAction.values) {
      expect(mapTrainCivilianKindForRadialAction(action), isNotNull);
    }
  });
}
