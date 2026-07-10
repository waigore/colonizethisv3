part of 'order_suggestion_core_expectations.dart';

void runOrderSuggestionCoreExpectationPart1(OrderSuggestionCoreTarget target) {
  switch (target) {
    case OrderSuggestionCoreTarget
        .suggestMoveOrdersOnlyReturnsMovesThatPassValidation:
      final moveGame = oscGame(
        worldState: oscWorld(
          oldWorld: RegionData(
            provinces: [
              oscProvince('p1', ownerId: OscIds.playerId),
              oscProvince('p2'),
            ],
            units: [oscExplorer()],
          ),
          tileKeysByRegionAndProvince: oscTilesByProvince({
            'p2': [OscIds.tile('p2', 0, 0)],
          }),
          playerVisibilityByTile: oscVisibility({
            OscIds.tile('p1', 0, 0): 'fullyVisible',
            OscIds.tile('p2', 0, 0): 'fogged',
          }),
        ),
      );
      final moveTopology = oscTwoProvincesConnected('p1', 'p2');
      final moves = oscSuggestMoves(moveGame, moveTopology);
      expect(moves.length, 1);
      expect(moves.first.unitId, 'u1');
      expect(moves.first.destinationTileKey, OscIds.tile('p2', 0, 0));
    case OrderSuggestionCoreTarget
        .suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility:
      final throwsGame = oscGame(
        worldState: oscWorld(
          oldWorld: RegionData(
            provinces: [
              oscProvince('p1', ownerId: OscIds.playerId),
              oscProvince('p2', ownerId: OscIds.playerId),
            ],
            units: [oscExplorer()],
          ),
        ),
      );
      expect(
        () => suggestMoveOrders(
          oscView(throwsGame, oscTwoProvincesConnected('p1', 'p2')),
          throwsGame,
          oscTwoProvincesConnected('p1', 'p2'),
          const Orders(),
        ),
        throwsStateError,
      );
    case OrderSuggestionCoreTarget
        .moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians:
      final unit = oscExplorer(
        provinceLocal: 'p1',
        tileKey: OscIds.tile('p2', 0, 0),
      );
      final civilianGame = oscGame(
        worldState: oscWorld(
          oldWorld: RegionData(
            provinces: [
              oscProvince('p1', ownerId: OscIds.playerId),
              oscProvince('p2', ownerId: OscIds.playerId),
              oscProvince('p3', ownerId: OscIds.playerId),
            ],
            units: [unit],
          ),
          tileKeysByRegionAndProvince: oscTilesByProvince({
            'p3': [OscIds.tile('p3', 0, 0)],
          }),
          playerVisibilityByTile: oscVisibility({
            OscIds.tile('p2', 0, 0): 'fullyVisible',
            OscIds.tile('p3', 0, 0): 'fogged',
          }),
        ),
      );
      final civilianTopology = oscProvinceTopology(
        ['p1', 'p2', 'p3'],
        edges: const [TopologyEdge(id1: 'p2', id2: 'p3')],
      );
      final civilianMoves = oscSuggestMoves(civilianGame, civilianTopology);
      expect(civilianMoves.length, 1);
      expect(civilianMoves.first.unitId, 'u1');
      expect(civilianMoves.first.destinationTileKey, OscIds.tile('p3', 0, 0));
      expect(
        oscView(civilianGame, civilianTopology).ownUnitsById['u1']!.locationProvinceId,
        OscIds.prov('p2'),
      );
    case OrderSuggestionCoreTarget.noExploreSuggestionWhenProvinceUnknown:
      oscExpectWorkTargetSuggestions(
        game: oscExplorerProvinceGame(),
        topology: oscProvinceTopology(['p1']),
        target: kWorkTargetExplore,
        expectNonEmpty: false,
      );
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersExploreTargetUsesKWorkTargetExplore:
      final t0 = OscIds.tile('p1', 0, 0);
      final t1 = OscIds.tile('p1', 1, 0);
      final exploreSuggestions = oscSuggestWork(
        oscExplorerProvinceGame(
          visibilityByTile: {t0: 'fullyVisible', t1: 'unknown'},
          tilesByLocal: {'p1': [t0, t1]},
        ),
        oscProvinceTopology(['p1']),
      );
      expect(
        oscWorkWithTarget(exploreSuggestions, kWorkTargetExplore),
        isNotEmpty,
      );
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope:
      final cacheGame = oscPartialRevealExploreCacheGame();
      final cacheTopology = oscEmptyTopology();
      final explore = oscWorkWithTarget(
        oscSuggestWork(cacheGame, cacheTopology),
        kWorkTargetExplore,
      );
      expect(explore, isNotEmpty);
      expect(
        Unit.provinceIdFromTileKey(explore.first.targetTileKey),
        OscIds.prov('p_partial'),
      );
    case OrderSuggestionCoreTarget
        .noProspectSuggestionWhenProvinceNotAtLeastFogged:
      oscExpectWorkTargetSuggestions(
        game: oscExplorerProvinceGame(
          ownerId: 'tribe1',
          visibilityByTile: {OscIds.tile('p1', 0, 0): 'unknown'},
        ),
        topology: oscProvinceTopology(['p1']),
        target: kWorkTargetProspect,
        expectNonEmpty: false,
      );
    case OrderSuggestionCoreTarget
        .prospectSuggestionWhenProvinceFoggedAndTilesInProvince:
      final tileKey = OscIds.tile('p1', 0, 0);
        oscExpectWorkTargetSuggestions(
          game: oscGame(
            worldState: oscExplorerProvinceGame(
              visibilityByTile: {tileKey: 'fogged'},
              tilesByLocal: {'p1': [tileKey]},
            ).worldState.copyWith(resourceByTileKey: {tileKey: 'iron'}),
          ),
          topology: oscProvinceTopology(['p1']),
          target: kWorkTargetProspect,
          expectNonEmpty: true,
          expectedTileKey: tileKey,
        );
    case OrderSuggestionCoreTarget
        .playerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder:
      final prospectGame = oscGame(
        worldState: oscExplorerProvinceGame(
          extraProvinceLocals: ['p2'],
          extraOwners: ['minor1'],
          visibilityByTile: {OscIds.tile('p1', 0, 0): 'fogged'},
          tilesByLocal: {
            'p1': [OscIds.tile('p1', 0, 0)],
            'p2': [OscIds.tile('p2', 0, 0)],
          },
        ).worldState,
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
      );
      final fromAll = allProvinces(prospectGame.worldState).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      final fromView = oscView(prospectGame, oscProvinceTopology(['p1', 'p2']))
          .provincesById
          .values
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      expect(fromView.length, fromAll.length);
      expect(
        fromView.map((p) => p.id).toList(),
        fromAll.map((p) => p.id).toList(),
      );
    case OrderSuggestionCoreTarget
        .getValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder:
      final reservedSetup = OscDualBuilderGrainTiles();
      final validB2 = getValidWorkOrderTileKeysWithVisibility(
        game: reservedSetup.game(),
        topology: reservedSetup.topology(),
        view: oscView(reservedSetup.game(), reservedSetup.topology()),
        unitId: 'b2',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: reservedSetup.ordersReservingTileA(),
      );
      expect(validB2, isNot(contains(reservedSetup.tileA)));
      expect(validB2, contains(reservedSetup.tileB));
    case OrderSuggestionCoreTarget
        .workSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile:
      final workerTileKey = OscIds.tile('p1', 0, 0);
      final workerGame = oscGame(
        worldState: oscWorld(
          oldWorld: RegionData(
            provinces: [oscProvince('p1', ownerId: OscIds.playerId)],
            units: [oscBuilder()],
          ),
          playerVisibilityByTile: oscVisibility({workerTileKey: 'fullyVisible'}),
          tileKeysByRegionAndProvince: oscTilesByProvince({'p1': [workerTileKey]}),
        ),
        players: [oscBuilderPlayer()],
      );
      final workerTopology = oscProvinceTopology(['p1']);
      for (final o in oscSuggestWork(workerGame, workerTopology)) {
        expect(o.unitId, 'u1');
        final u = oscView(workerGame, workerTopology).ownUnitsById[o.unitId];
        expect(u, isNotNull);
        expect(u!.locationProvinceId, OscIds.prov('p1'));
      }
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes:
      final tileNoResource = OscIds.tile('p1', 0, 0);
        final tileWithResource = OscIds.tile('p1', 1, 0);
        oscExpectBuildImprovementFirstTile(
          game: oscBuilderImprovementGame(
            tileNoResource: tileNoResource,
            tileWithResource: tileWithResource,
          ),
          topology: oscProvinceTopology(['p1']),
          expectedTileKey: tileWithResource,
          unitId: 'u1',
        );
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile:
      final tileP1 = OscIds.tile('p1', 0, 0);
        final tileP2 = OscIds.tile('p2', 0, 0);
        oscExpectBuildImprovementFirstTile(
          game: oscBuilderImprovementGame(
            tileNoResource: tileP1,
            tileWithResource: tileP2,
            secondProvinceLocal: 'p2',
            secondTile: tileP2,
          ),
          topology: oscProvinceTopology(['p1', 'p2']),
          expectedTileKey: tileP2,
          unitId: 'u1',
        );
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder:
      final setup = OscDualBuilderGrainTiles();
        oscExpectBuildImprovementFirstTile(
          game: setup.game(),
          topology: setup.topology(),
          expectedTileKey: setup.tileB,
          orders: setup.ordersReservingTileA(),
        );
    default:
      throw ArgumentError.value(
        target,
        'target',
        'runOrderSuggestionCoreExpectationPart1',
      );
  }
}

