part of 'order_engine_validate_work_expectations.dart';


List<OrderValidationResult> _runPurchaseLandValidation(Game game) {
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    WorkOrder(
      unitId: 'merchant1',
      target: kWorkTargetPurchaseLand,
      targetTileKey: PurchaseLandTestFixture.tileKey,
    ),
  );
  return engine.validatePlayerOrdersWithContext(
    game,
    PurchaseLandTestFixture.topology(),
    'p1',
  );
}

OrderValidationResult _runUpgradeTownValidation(Game game) {
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'b1',
      target: kWorkTargetUpgradeTown,
      targetTileKey: ValidateWorkOw.tileKey,
    ),
  );
  return engine
      .validatePlayerOrdersWithContext(
        game,
        ValidateWorkOw.topology(),
        'p1',
      )
      .single;
}

OrderValidationResult _runMinorProvinceRoadValidation(Game game) {
  final engine = OrderEngine();
  engine.addWorkOrder(
    'gp1',
    WorkOrder(
      unitId: 'e1',
      target: kWorkTargetBuildRoad,
      targetTileKey: minorProvinceRoadTileKey(),
    ),
  );
  return engine
      .validatePlayerOrdersWithContext(
        game,
        minorProvinceRoadTopology(),
        'gp1',
      )
      .single;
}

void _rejectsSecondPendingWorkOrderForSameUnitInOneTurn() {
  final game = dualTilePendingWorkGame();
  const tileA = ValidateWorkOw.tileKey;
  const tileB = '${ValidateWorkOw.provinceId}|1|0';

  final engine = OrderEngine();
  engine
    ..addWorkOrder(
      'p1',
      const WorkOrder(
        unitId: 'builder1',
        target: kWorkTargetBuildImprovement,
        targetTileKey: tileA,
      ),
    )
    ..addWorkOrder(
      'p1',
      const WorkOrder(
        unitId: 'builder1',
        target: kWorkTargetBuildImprovement,
        targetTileKey: tileB,
      ),
    );

  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );
  expect(results, hasLength(2));
  expect(results.first.status, OrderValidationStatus.accepted);
  expect(results.last.status, OrderValidationStatus.rejected);
  expect(
    results.last.reason,
    contains('Only one work order per unit is allowed each turn'),
  );
}

void _rejectsPurchaseLandWhenNoEmbassyWithMinor() {
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(treasury: 500),
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('embassy'));
}

void _rejectsPurchaseLandWhenAtWarWithFaction() {
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'p1',
          factionId2: 'minor1',
          state: RelationState.atWar,
        ),
      ],
    ),
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('war'));
}

void _rejectsPurchaseLandWhenInsufficientTreasury() {
  const cost = 15 * 10; // grain default base 10
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(
      treasury: cost - 1,
      overtureStates: purchaseLandEmbassyOverture,
    ),
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('Insufficient treasury'));
}

void _rejectsPurchaseLandWhenTileHasNoResource() {
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      resourceByTileKey: {},
    ),
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('no resource'));
}

void _rejectsPurchaseLandWhenMineralTileNotProspected() {
  final tk = PurchaseLandTestFixture.tileKey;
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      resourceByTileKey: {tk: 'iron'},
      playerProspectedTiles: {},
    ),
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('prospected'));
}

void
_acceptsPurchaseLandWithEmbassyAtPeaceSufficientTreasuryTileWithResource() {
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
    ),
  );
  expect(results.single.status, OrderValidationStatus.accepted);
}

void
_rejectsSecondBuilderEngineerMerchantWorkOrderOnSameTileForSamePlayerPerTileExclusivity() {
  const tileKey = ValidateWorkOw.tileKey;
  final game = builderEngineerSameTileExclusivityGame();

  final engine = OrderEngine();
  engine
    ..addWorkOrder(
      'p1',
      const WorkOrder(
        unitId: 'builder1',
        target: kWorkTargetBuildImprovement,
        targetTileKey: tileKey,
      ),
    )
    ..addWorkOrder(
      'p1',
      const WorkOrder(
        unitId: 'engineer1',
        target: kWorkTargetBuildRoad,
        targetTileKey: tileKey,
      ),
    );

  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );

  expect(results.length, 2);
  expect(results[0].status, OrderValidationStatus.accepted);
  expect(results[1].status, OrderValidationStatus.rejected);
  expect(
    results[1].reason,
    contains('Tile already has development or purchase work'),
  );
}

void _acceptsPurchaseLandForMineralWhenProspected() {
  final tk = PurchaseLandTestFixture.tileKey;
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      resourceByTileKey: {tk: 'iron'},
      playerProspectedTiles: {
        'p1': {tk},
      },
    ),
  );
  expect(results.single.status, OrderValidationStatus.accepted);
}

void _rejectsPurchaseLandWhenTileAlreadyPurchasedByAnotherGP() {
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p2'},
    ),
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(
    results.single.reason,
    contains('Tile already purchased by another power'),
  );
}

void _rejectsPurchaseLandWhenTileAlreadyOwnedBySamePlayer() {
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p1'},
    ),
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('You already own this tile'));
}
