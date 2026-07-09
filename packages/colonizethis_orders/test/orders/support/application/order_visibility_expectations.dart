// Compact order-visibility assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_visibility.dart';
import 'package:colonizethis_orders/src/orders/order_work_constants.dart';
import 'package:colonizethis_test/test.dart';

import 'order_visibility_fixtures.dart';

/// Pins for [orderVisibilityScenarios] rows.
enum OrderVisibilityTarget {
  provinceHasAtLeastVisibilityNoTileKey,
  provinceHasAtLeastVisibilityTileMeetsMin,
  provinceHasAtLeastVisibilityIgnoresBadKeyParts,
  provinceHasAtLeastVisibilityWrongPartCount,
  tileHasAtLeastVisibilityTrue,
  tileHasAtLeastVisibilityUnknown,
  moveSourceVisibilityOkFogged,
  moveDestVisibilityOkFogged,
  workExplorePartialReveal,
  workExploreRejectsNoUnknownLand,
  workExploreRejectsWithoutWorldState,
  workProspectRequiresFogged,
  workBuildImprovementOwnedProvince,
  workUnknownTargetReturnsFalse,
  workCounterSpyOwnedWithoutFogged,
  workBuildFortFoggedOwned,
  workBuildRoadTargetTileKey,
}

void runOrderVisibilityExpectation(OrderVisibilityTarget target) {
  switch (target) {
    case OrderVisibilityTarget.provinceHasAtLeastVisibilityNoTileKey:
      final view = orderVisibilityView0(
        visibilityByTile: {
          'oldWorld|p1|0|0': VisibilityLevel.fogged,
        },
      );
      expect(
        provinceHasAtLeastVisibility(
          view, 'oldWorld', 'p2', VisibilityLevel.fogged,
        ),
        isFalse,
      );

    case OrderVisibilityTarget.provinceHasAtLeastVisibilityTileMeetsMin:
      final view = orderVisibilityView0(
        visibilityByTile: {
          'oldWorld|p1|0|0': VisibilityLevel.fogged,
        },
      );
      expect(
        provinceHasAtLeastVisibility(
          view, 'oldWorld', 'p1', VisibilityLevel.fogged,
        ),
        isTrue,
      );

    case OrderVisibilityTarget.provinceHasAtLeastVisibilityIgnoresBadKeyParts:
      final view = orderVisibilityView0(
        visibilityByTile: {
          'badkey': VisibilityLevel.fullyVisible,
        },
      );
      expect(
        provinceHasAtLeastVisibility(
          view, 'oldWorld', 'p1', VisibilityLevel.fogged,
        ),
        isFalse,
      );

    case OrderVisibilityTarget.provinceHasAtLeastVisibilityWrongPartCount:
      final view = orderVisibilityView0(
        visibilityByTile: {'oldWorld|p1|0': VisibilityLevel.fullyVisible},
      );
      expect(
        provinceHasAtLeastVisibility(
          view, 'oldWorld', 'p1', VisibilityLevel.fogged,
        ),
        isFalse,
      );

    case OrderVisibilityTarget.tileHasAtLeastVisibilityTrue:
      final view = orderVisibilityView0(
        visibilityByTile: {'t1': VisibilityLevel.fullyVisible},
      );
      expect(
        tileHasAtLeastVisibility(view, 't1', VisibilityLevel.fogged),
        isTrue,
      );

    case OrderVisibilityTarget.tileHasAtLeastVisibilityUnknown:
      final view = orderVisibilityView0();
      expect(
        tileHasAtLeastVisibility(view, 'missing', VisibilityLevel.fogged),
        isFalse,
      );

    case OrderVisibilityTarget.moveSourceVisibilityOkFogged:
      final view = orderVisibilityView0(
        visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.fogged},
      );
      expect(moveSourceVisibilityOk(view, 'oldWorld', 'p1'), isTrue);

    case OrderVisibilityTarget.moveDestVisibilityOkFogged:
      final view = orderVisibilityView0(
        visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.fogged},
      );
      expect(
        moveDestVisibilityOk(view, 'oldWorld', 'p1', 'inf'),
        isTrue,
      );

    case OrderVisibilityTarget.workExplorePartialReveal:
      final view = orderVisibilityView0(
        visibilityByTile: {
          'oldWorld|p1|0|0': VisibilityLevel.fogged,
          'oldWorld|p1|1|0': VisibilityLevel.unknown,
        },
      );
      final unit = orderVisibilityInfantryUnit();
      final ws = orderVisibilityWorldStateTwoLandTilesP1();
      expect(
        workOrderVisibilityOk(
          view,
          unit,
          kWorkTargetExplore,
          targetTileKey: 'oldWorld|p1|0|0',
          worldState: ws,
        ),
        isTrue,
      );

    case OrderVisibilityTarget.workExploreRejectsNoUnknownLand:
      final view = orderVisibilityView0(
        visibilityByTile: {
          'oldWorld|p1|0|0': VisibilityLevel.fogged,
          'oldWorld|p1|1|0': VisibilityLevel.fogged,
        },
      );
      final unit = orderVisibilityInfantryUnit();
      final ws = orderVisibilityWorldStateTwoLandTilesP1();
      expect(
        workOrderVisibilityOk(
          view,
          unit,
          kWorkTargetExplore,
          targetTileKey: 'oldWorld|p1|0|0',
          worldState: ws,
        ),
        isFalse,
      );

    case OrderVisibilityTarget.workExploreRejectsWithoutWorldState:
      final view = orderVisibilityView0(
        visibilityByTile: {
          'oldWorld|p1|0|0': VisibilityLevel.fogged,
          'oldWorld|p1|1|0': VisibilityLevel.unknown,
        },
      );
      final unit = orderVisibilityInfantryUnit();
      expect(
        workOrderVisibilityOk(
          view,
          unit,
          kWorkTargetExplore,
          targetTileKey: 'oldWorld|p1|0|0',
        ),
        isFalse,
      );

    case OrderVisibilityTarget.workProspectRequiresFogged:
      final view = orderVisibilityView0(
        visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.fogged},
      );
      final unit = orderVisibilityInfantryUnit();
      expect(workOrderVisibilityOk(view, unit, kWorkTargetProspect), isTrue);

    case OrderVisibilityTarget.workBuildImprovementOwnedProvince:
      const r = 'oldWorld';
      const p = 'p1';
      final fullId = '$r|$p';
      final view = orderVisibilityView0(
        provincesById: {
          fullId: orderVisibilityOwnedProvince(regionId: r, localId: p),
        },
      );
      final unit = orderVisibilityInfantryUnit();
      expect(
        workOrderVisibilityOk(view, unit, kWorkTargetBuildImprovement),
        isTrue,
      );

    case OrderVisibilityTarget.workUnknownTargetReturnsFalse:
      final view = orderVisibilityView0(
        visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.fullyVisible},
      );
      final unit = orderVisibilityInfantryUnit(
        tileKey: 'oldWorld|p1|0|0',
      );
      expect(
        workOrderVisibilityOk(view, unit, 'unknown_work'),
        isFalse,
      );

    case OrderVisibilityTarget.workCounterSpyOwnedWithoutFogged:
      const r = 'oldWorld';
      const p = 'p1';
      final fullId = '$r|$p';
      final view = orderVisibilityView0(
        provincesById: {
          fullId: orderVisibilityOwnedProvince(regionId: r, localId: p),
        },
      );
      final unit = orderVisibilityInfantryUnit(type: kUnitTypeSpy);
      expect(
        workOrderVisibilityOk(view, unit, kWorkTargetCounterSpy),
        isTrue,
      );

    case OrderVisibilityTarget.workBuildFortFoggedOwned:
      const r = 'oldWorld';
      const p = 'p1';
      final fullId = '$r|$p';
      final view = orderVisibilityView0(
        provincesById: {
          fullId: orderVisibilityOwnedProvince(regionId: r, localId: p),
        },
        visibilityByTile: {'$r|$p|0|0': VisibilityLevel.fogged},
      );
      final unit = orderVisibilityInfantryUnit();
      expect(
        workOrderVisibilityOk(view, unit, kWorkTargetBuildFort),
        isTrue,
      );

    case OrderVisibilityTarget.workBuildRoadTargetTileKey:
      final view = orderVisibilityView0(
        visibilityByTile: {'oldWorld|p2|1|1': VisibilityLevel.fogged},
        provincesById: {
          'oldWorld|p2': orderVisibilityOwnedProvince(
            regionId: 'oldWorld',
            localId: 'p2',
          ),
        },
      );
      final unit = orderVisibilityInfantryUnit(
        type: 'engineer',
        locationProvinceId: 'oldWorld|p2',
      );
      expect(
        workOrderVisibilityOk(
          view,
          unit,
          kWorkTargetBuildRoad,
          targetTileKey: 'oldWorld|p2|1|1',
        ),
        isTrue,
      );
  }
}
