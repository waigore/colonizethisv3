part of 'order_engine_validate_work_expectations.dart';

void _rejectsSecondPendingWorkOrderForSameUnitInOneTurn() {
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

  vwExpectWorkResults(
    engine.validatePlayerOrdersWithContext(
      dualTilePendingWorkGame(),
      ValidateWorkOw.topology(),
      'p1',
    ),
    statuses: const [
      OrderValidationStatus.accepted,
      OrderValidationStatus.rejected,
    ],
    lastReasonContains: 'Only one work order per unit is allowed each turn',
  );
}

void _rejectsPurchaseLandWhenNoEmbassyWithMinor() {
  vwExpectPurchaseLandRejected(
    vwPurchaseLandGame(treasury: 500),
    reasonContains: 'embassy',
  );
}

void _rejectsPurchaseLandWhenAtWarWithFaction() {
  vwExpectPurchaseLandRejected(
    vwPurchaseLandGame(
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
    reasonContains: 'war',
  );
}

void _rejectsPurchaseLandWhenInsufficientTreasury() {
  const cost = 15 * 10; // grain default base 10
  vwExpectPurchaseLandRejected(
    vwPurchaseLandGame(
      treasury: cost - 1,
      overtureStates: purchaseLandEmbassyOverture,
    ),
    reasonContains: 'Insufficient treasury',
  );
}

void _rejectsPurchaseLandWhenTileHasNoResource() {
  vwExpectPurchaseLandRejected(
    vwPurchaseLandGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      resourceByTileKey: {},
    ),
    reasonContains: 'no resource',
  );
}

void _rejectsPurchaseLandWhenMineralTileNotProspected() {
  final tk = PurchaseLandTestFixture.tileKey;
  vwExpectPurchaseLandRejected(
    vwPurchaseLandGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      resourceByTileKey: {tk: 'iron'},
      playerProspectedTiles: {},
    ),
    reasonContains: 'prospected',
  );
}

void
_acceptsPurchaseLandWithEmbassyAtPeaceSufficientTreasuryTileWithResource() {
  vwExpectPurchaseLandAccepted(
    vwPurchaseLandGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
    ),
  );
}

void
_rejectsSecondBuilderEngineerMerchantWorkOrderOnSameTileForSamePlayerPerTileExclusivity() {
  const tileKey = ValidateWorkOw.tileKey;
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

  vwExpectWorkResults(
    engine.validatePlayerOrdersWithContext(
      builderEngineerSameTileExclusivityGame(),
      ValidateWorkOw.topology(),
      'p1',
    ),
    statuses: const [
      OrderValidationStatus.accepted,
      OrderValidationStatus.rejected,
    ],
    lastReasonContains: 'Tile already has development or purchase work',
  );
}

void _acceptsPurchaseLandForMineralWhenProspected() {
  final tk = PurchaseLandTestFixture.tileKey;
  vwExpectPurchaseLandAccepted(
    vwPurchaseLandGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      resourceByTileKey: {tk: 'iron'},
      playerProspectedTiles: {
        'p1': {tk},
      },
    ),
  );
}

void _rejectsPurchaseLandWhenTileAlreadyPurchasedByAnotherGP() {
  vwExpectPurchaseLandRejected(
    vwPurchaseLandGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p2'},
    ),
    reasonContains: 'Tile already purchased by another power',
  );
}

void _rejectsPurchaseLandWhenTileAlreadyOwnedBySamePlayer() {
  vwExpectPurchaseLandRejected(
    vwPurchaseLandGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p1'},
    ),
    reasonContains: 'You already own this tile',
  );
}
