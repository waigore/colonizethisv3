// Table-driven order-visibility scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_visibility.dart';
import 'package:colonizethis_orders/src/orders/order_work_constants.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_visibility_fixtures.dart';

void ovRunProvinceHasAtLeastVisibilityNoTileKey() {
  final view = orderVisibilityView0(
    visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.fogged},
  );
  expect(
    provinceHasAtLeastVisibility(
      view,
      'oldWorld',
      'p2',
      VisibilityLevel.fogged,
    ),
    isFalse,
  );
}

void ovRunProvinceHasAtLeastVisibilityTileMeetsMin() {
  final view = orderVisibilityView0(
    visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.fogged},
  );
  expect(
    provinceHasAtLeastVisibility(
      view,
      'oldWorld',
      'p1',
      VisibilityLevel.fogged,
    ),
    isTrue,
  );
}

void ovRunProvinceHasAtLeastVisibilityIgnoresBadKeyParts() {
  final view = orderVisibilityView0(
    visibilityByTile: {'badkey': VisibilityLevel.fullyVisible},
  );
  expect(
    provinceHasAtLeastVisibility(
      view,
      'oldWorld',
      'p1',
      VisibilityLevel.fogged,
    ),
    isFalse,
  );
}

void ovRunProvinceHasAtLeastVisibilityWrongPartCount() {
  final view = orderVisibilityView0(
    visibilityByTile: {'oldWorld|p1|0': VisibilityLevel.fullyVisible},
  );
  expect(
    provinceHasAtLeastVisibility(
      view,
      'oldWorld',
      'p1',
      VisibilityLevel.fogged,
    ),
    isFalse,
  );
}

void ovRunTileHasAtLeastVisibilityTrue() {
  final view = orderVisibilityView0(
    visibilityByTile: {'t1': VisibilityLevel.fullyVisible},
  );
  expect(tileHasAtLeastVisibility(view, 't1', VisibilityLevel.fogged), isTrue);
}

void ovRunTileHasAtLeastVisibilityUnknown() {
  final view = orderVisibilityView0();
  expect(
    tileHasAtLeastVisibility(view, 'missing', VisibilityLevel.fogged),
    isFalse,
  );
}

void ovRunMoveSourceVisibilityOkFogged() {
  final view = orderVisibilityView0(
    visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.fogged},
  );
  expect(moveSourceVisibilityOk(view, 'oldWorld', 'p1'), isTrue);
}

void ovRunMoveDestVisibilityOkFogged() {
  final view = orderVisibilityView0(
    visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.fogged},
  );
  expect(moveDestVisibilityOk(view, 'oldWorld', 'p1', 'inf'), isTrue);
}

void ovRunWorkExplorePartialReveal() {
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
}

void ovRunWorkExploreRejectsNoUnknownLand() {
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
}

void ovRunWorkExploreRejectsWithoutWorldState() {
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
}

void ovRunWorkProspectRequiresFogged() {
  final view = orderVisibilityView0(
    visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.fogged},
  );
  final unit = orderVisibilityInfantryUnit();
  expect(workOrderVisibilityOk(view, unit, kWorkTargetProspect), isTrue);
}

void ovRunWorkBuildImprovementOwnedProvince() {
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
}

void ovRunWorkUnknownTargetReturnsFalse() {
  final view = orderVisibilityView0(
    visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.fullyVisible},
  );
  final unit = orderVisibilityInfantryUnit(tileKey: 'oldWorld|p1|0|0');
  expect(workOrderVisibilityOk(view, unit, 'unknown_work'), isFalse);
}

void ovRunWorkCounterSpyOwnedWithoutFogged() {
  const r = 'oldWorld';
  const p = 'p1';
  final fullId = '$r|$p';
  final view = orderVisibilityView0(
    provincesById: {
      fullId: orderVisibilityOwnedProvince(regionId: r, localId: p),
    },
  );
  final unit = orderVisibilityInfantryUnit(type: kUnitTypeSpy);
  expect(workOrderVisibilityOk(view, unit, kWorkTargetCounterSpy), isTrue);
}

void ovRunWorkBuildFortFoggedOwned() {
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
  expect(workOrderVisibilityOk(view, unit, kWorkTargetBuildFort), isTrue);
}

void ovRunWorkBuildRoadTargetTileKey() {
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

/// One row in order-visibility scenario tables.

/// Scenarios for provinceHasAtLeastVisibility.
List<RunnableScenario> provinceHasAtLeastVisibilityScenarios() => const [
  RunnableScenario(
    label: 'false when no tile has 4-part key for region/province',
    run: ovRunProvinceHasAtLeastVisibilityNoTileKey,
  ),
  RunnableScenario(
    label: 'true when a tile in province has at least min visibility',
    run: ovRunProvinceHasAtLeastVisibilityTileMeetsMin,
  ),
  RunnableScenario(
    label: 'ignores tile keys with wrong number of parts',
    run: ovRunProvinceHasAtLeastVisibilityIgnoresBadKeyParts,
  ),
  RunnableScenario(
    label: 'provinceHasAtLeastVisibility returns false when parts.length != 4',
    run: ovRunProvinceHasAtLeastVisibilityWrongPartCount,
  ),
];

/// Scenarios for tileHasAtLeastVisibility.
List<RunnableScenario> tileHasAtLeastVisibilityScenarios() => const [
  RunnableScenario(
    label: 'true when tile has at least min level',
    run: ovRunTileHasAtLeastVisibilityTrue,
  ),
  RunnableScenario(
    label: 'false when tile unknown',
    run: ovRunTileHasAtLeastVisibilityUnknown,
  ),
];

/// Scenarios for moveSourceVisibilityOk.
List<RunnableScenario> moveSourceVisibilityOkScenarios() => const [
  RunnableScenario(
    label: 'true when province has at least fogged',
    run: ovRunMoveSourceVisibilityOkFogged,
  ),
];

/// Scenarios for moveDestVisibilityOk.
List<RunnableScenario> moveDestVisibilityOkScenarios() => const [
  RunnableScenario(
    label: 'true when province has at least fogged',
    run: ovRunMoveDestVisibilityOkFogged,
  ),
];

/// Scenarios for workOrderVisibilityOk.
List<RunnableScenario> workOrderVisibilityOkScenarios() => const [
  RunnableScenario(
    label: 'explore requires partial reveal (known + unknown land tiles)',
    run: ovRunWorkExplorePartialReveal,
  ),
  RunnableScenario(
    label: 'explore rejects province with no unknown land tile',
    run: ovRunWorkExploreRejectsNoUnknownLand,
  ),
  RunnableScenario(
    label: 'explore rejects when worldState omitted',
    run: ovRunWorkExploreRejectsWithoutWorldState,
  ),
  RunnableScenario(
    label: 'prospect requires at least fogged',
    run: ovRunWorkProspectRequiresFogged,
  ),
  RunnableScenario(
    label: 'build_improvement allows owned province',
    run: ovRunWorkBuildImprovementOwnedProvince,
  ),
  RunnableScenario(
    label: 'unknown workTarget returns false',
    run: ovRunWorkUnknownTargetReturnsFalse,
  ),
  RunnableScenario(
    label: 'counter_spy allows owned province without fogged',
    run: ovRunWorkCounterSpyOwnedWithoutFogged,
  ),
  RunnableScenario(
    label: 'build_fort with fogged visibility on owned province',
    run: ovRunWorkBuildFortFoggedOwned,
  ),
  RunnableScenario(
    label:
        'build_road with targetTileKey uses tile key for region and province',
    run: ovRunWorkBuildRoadTargetTileKey,
  ),
];
