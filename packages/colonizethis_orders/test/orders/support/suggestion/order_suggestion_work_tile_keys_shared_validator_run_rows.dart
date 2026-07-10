// Scenario run tear-offs for order_suggestion_work_tile_keys_shared_validator (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_context.dart';
import 'package:colonizethis_test/test.dart';
import 'order_suggestion_work_tile_keys_shared_validator_fixtures.dart';

void oswtkRunSharedCandidateValidatorMatchesDefaultPath() {
  final fixture = workTileKeysSharedValidatorFixture();
  final baseline = getValidWorkOrderTileKeysWithVisibility(
    game: fixture.game,
    topology: fixture.topology,
    view: fixture.view,
    unitId: 'b1',
    workTarget: kWorkTargetBuildImprovement,
    currentOrders: fixture.orders,
  );
  final shared = buildIncrementalCandidateValidator(
    game: fixture.game,
    topology: fixture.topology,
    playerId: workTileKeysSharedValidatorPlayerId,
    baseOrders: fixture.orders,
  );
  final withShared = getValidWorkOrderTileKeysWithVisibility(
    game: fixture.game,
    topology: fixture.topology,
    view: fixture.view,
    unitId: 'b1',
    workTarget: kWorkTargetBuildImprovement,
    currentOrders: fixture.orders,
    sharedCandidateValidator: shared,
  );
  expect(withShared, equals(baseline));
}

void oswtkRunPlayerOwnedProvinceIdsMatchesDefaultPath() {
  final fixture = workTileKeysSharedValidatorFixture();
  final baseline = getValidWorkOrderTileKeysWithVisibility(
    game: fixture.game,
    topology: fixture.topology,
    view: fixture.view,
    unitId: 'b1',
    workTarget: kWorkTargetBuildImprovement,
    currentOrders: fixture.orders,
  );
  final withOwnedIds = getValidWorkOrderTileKeysWithVisibility(
    game: fixture.game,
    topology: fixture.topology,
    view: fixture.view,
    unitId: 'b1',
    workTarget: kWorkTargetBuildImprovement,
    currentOrders: fixture.orders,
    playerOwnedProvinceIds: fixture.ownedIds,
  );
  expect(withOwnedIds, equals(baseline));
}

void oswtkRunOptionalUnitsByIdMatchesDefaultPath() {
  final fixture = workTileKeysSharedValidatorFixture();
  final baseline = getValidWorkOrderTileKeysWithVisibility(
    game: fixture.game,
    topology: fixture.topology,
    view: fixture.view,
    unitId: 'b1',
    workTarget: kWorkTargetBuildImprovement,
    currentOrders: fixture.orders,
  );
  final withUnitsById = getValidWorkOrderTileKeysWithVisibility(
    game: fixture.game,
    topology: fixture.topology,
    view: fixture.view,
    unitId: 'b1',
    workTarget: kWorkTargetBuildImprovement,
    currentOrders: fixture.orders,
    resolution: orderResolutionContextFromView(
      fixture.view,
      fixture.game,
      unitsById: fixture.unitsById,
    ),
  );
  expect(withUnitsById, equals(baseline));
}

void oswtkRunMatchesPriorBehaviorForBuilderImprovementTiles() {
  final fixture = workTileKeysSharedValidatorFixture();
  final keys = getValidWorkOrderTileKeys(
    fixture.game,
    fixture.topology,
    workTileKeysSharedValidatorPlayerId,
    'b1',
    kWorkTargetBuildImprovement,
    fixture.orders,
  );
  expect(keys, contains(workTileKeysSharedValidatorTileA));
  expect(keys, contains(workTileKeysSharedValidatorTileB));
}

void oswtkRunSharedViewAndValidatorMatchesDefaultPath() {
  final fixture = workTileKeysSharedValidatorFixture();
  final baseline = getValidWorkOrderTileKeys(
    fixture.game,
    fixture.topology,
    workTileKeysSharedValidatorPlayerId,
    'b1',
    kWorkTargetBuildImprovement,
    fixture.orders,
  );
  final membership = DiplomacyFactionMembership.from(fixture.game);
  final shared = buildIncrementalCandidateValidator(
    game: fixture.game,
    topology: fixture.topology,
    playerId: workTileKeysSharedValidatorPlayerId,
    baseOrders: fixture.orders,
    resolution: orderResolutionContextFromView(
      fixture.view,
      fixture.game,
      unitsById: fixture.unitsById,
    ),
    factionMembership: membership,
  );
  final withShared = getValidWorkOrderTileKeys(
    fixture.game,
    fixture.topology,
    workTileKeysSharedValidatorPlayerId,
    'b1',
    kWorkTargetBuildImprovement,
    fixture.orders,
    resolution: orderResolutionContextFromView(
      fixture.view,
      fixture.game,
      unitsById: fixture.unitsById,
    ),
    factionMembership: membership,
    sharedCandidateValidator: shared,
    playerOwnedProvinceIds: fixture.ownedIds,
  );
  expect(withShared, equals(baseline));
}
