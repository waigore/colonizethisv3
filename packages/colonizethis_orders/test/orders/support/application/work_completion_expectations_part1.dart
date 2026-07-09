part of 'work_completion_expectations.dart';

Unit _builderCompletingImprovement({
  String ownerId = 'p1',
  int totalTurns = 1,
  int remainingTurns = 1,
  bool withOriginAssignment = true,
}) {
  return workAppWorkingUnit(
    type: kUnitTypeBuilder,
    workTarget: kWorkTargetBuildImprovement,
    ownerId: ownerId,
    totalTurns: totalTurns,
    remainingTurns: remainingTurns,
    originTileKey: withOriginAssignment ? WorkAppIds.originTileKey : null,
    assignedTileKey: withOriginAssignment ? WorkAppIds.tileKey : null,
  );
}

Game _completionGame({
  required List<Unit> units,
  TileMapState? tileState,
  List<Province>? provinces,
  List<Player>? players,
  Map<String, String>? resourceByTileKey,
  Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
  Map<String, Map<String, String>>? playerVisibilityByTile,
  Map<String, String>? portsByProvinceSeaboard,
  int turnNumber = 0,
  Map<String, bool>? aiControlByGpId,
  String? lastHumanCompletedResearchCategory,
  int? lastHumanResearchCategoryCompletionTurn,
}) {
  return workAppOwnedGame(
    units: units,
    provinces: provinces,
    players: players,
    tileState: tileState,
    resourceByTileKey: resourceByTileKey,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    playerVisibilityByTile: playerVisibilityByTile,
    portsByProvinceSeaboard: portsByProvinceSeaboard,
    turnNumber: turnNumber,
    aiControlByGpId: aiControlByGpId,
    lastHumanCompletedResearchCategory: lastHumanCompletedResearchCategory,
    lastHumanResearchCategoryCompletionTurn:
        lastHumanResearchCategoryCompletionTurn,
  );
}

void
_buildImprovementCompletionIncreasesImprovementLevelAndClearsCurrentWork() {
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [_builderCompletingImprovement()],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 0),
    ),
    workAppProcessWorkOrders(),
  );
  expect(next.worldState.tileState.improvementLevel(WorkAppIds.tileKey), 1);
  final after = next.worldState.oldWorld.units.single;
  expect(after.tileKey, WorkAppIds.tileKey);
  expect(after.originTileKey, isNull);
  expect(after.assignedTileKey, isNull);
}

void _buildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile() {
  final next = applyBuildAndWorkOrders(
    _completionGame(
      turnNumber: 2,
      units: [_builderCompletingImprovement()],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 0),
      resourceByTileKey: const {WorkAppIds.tileKey: 'grain'},
    ),
    workAppProcessWorkOrders(),
  );
  expect(next.lastHumanCompletedResearchCategory, 'gathering');
  expect(next.lastHumanResearchCategoryCompletionTurn, 2);
}

void
_buildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint() {
  const aiId = 'ai1';
  final next = applyBuildAndWorkOrders(
    _completionGame(
      turnNumber: 1,
      units: [_builderCompletingImprovement(ownerId: aiId)],
      provinces: [workAppOwnedProvince(ownerId: aiId)],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 0),
      resourceByTileKey: const {WorkAppIds.tileKey: 'coal'},
      players: const [
        Player(id: 'human', displayName: 'H', isHuman: true),
        Player(id: aiId, displayName: 'AI', isHuman: false),
      ],
      aiControlByGpId: const {aiId: true},
      lastHumanCompletedResearchCategory: 'gathering',
      lastHumanResearchCategoryCompletionTurn: 0,
    ),
    workAppProcessWorkOrders(),
  );
  final envy = next.dossierEvidenceEntries
      .where((e) => e.agendaType == 'envy')
      .toList();
  expect(envy, isNotEmpty);
  expect(envy.single.subjectId, aiId);
  expect(envy.single.scoreDelta, 1);
}

void _buildImprovementCompletionRaisesStoredLevelFrom3To4GlobalMax() {
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [_builderCompletingImprovement()],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 3),
      resourceByTileKey: const {WorkAppIds.tileKey: 'grain'},
    ),
    workAppProcessWorkOrders(),
  );
  expect(next.worldState.tileState.improvementLevel(WorkAppIds.tileKey), 4);
}

void _buildImprovementCompletionDoesNotReApplyExtractionTechCap1291() {
  // Assign-time would reject 3→4 with extraction cap 2; completion still applies +1 to stored level.
  expect(
    extractionCapForResourceForUnlocked(const {kTechIdSawMill: true}, 'grain'),
    1,
  );
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [_builderCompletingImprovement()],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 3),
      resourceByTileKey: const {WorkAppIds.tileKey: 'grain'},
      players: [
        workAppPlayer(techUnlocked: const {kTechIdSawMill: true}),
      ],
    ),
    workAppProcessWorkOrders(),
  );
  expect(next.worldState.tileState.improvementLevel(WorkAppIds.tileKey), 4);
}

void _workCancelledWhenProvinceContainingTargetTileIsConquered376() {
  // Unit p1 is working on a tile in P1; province P1 is conquered by p2.
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [_builderCompletingImprovement(totalTurns: 2, remainingTurns: 2)],
      // Province owned by p2 (conquered); unit still belongs to p1.
      provinces: [workAppOwnedProvince(ownerId: 'p2')],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 0),
      players: const [
        Player(id: 'p1', displayName: 'P1', isHuman: true),
        Player(id: 'p2', displayName: 'P2', isHuman: true),
      ],
    ),
    workAppProcessWorkOrders(),
  );
  final uAfter = next.worldState.oldWorld.units.single;
  expect(uAfter.status, UnitStatus.idle);
  expect(uAfter.currentWork, isNull);
  expect(uAfter.tileKey, WorkAppIds.originTileKey);
  expect(uAfter.originTileKey, isNull);
  expect(uAfter.assignedTileKey, isNull);
  // Improvement not applied (work was cancelled).
  expect(next.worldState.tileState.improvementLevel(WorkAppIds.tileKey), 0);
}

void _multiTurnWorkDecrementsRemainingTurnsAndCompletesOnlyWhenZero() {
  final game = _completionGame(
    units: [
      _builderCompletingImprovement(
        totalTurns: 2,
        remainingTurns: 2,
        withOriginAssignment: false,
      ),
    ],
    tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 0),
  );
  final afterFirst = applyBuildAndWorkOrders(game, workAppProcessWorkOrders());
  expect(
    afterFirst.worldState.tileState.improvementLevel(WorkAppIds.tileKey),
    0,
  );
  final uAfterFirst = afterFirst.worldState.oldWorld.units.single;
  expect(uAfterFirst.currentWork!.remainingTurns, 1);
  final afterSecond = applyBuildAndWorkOrders(
    afterFirst,
    workAppProcessWorkOrders(),
  );
  expect(
    afterSecond.worldState.tileState.improvementLevel(WorkAppIds.tileKey),
    1,
  );
}

void _exploreCompletionSetsVisibilityAndClearsCurrentWork() {
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [
        workAppWorkingUnit(
          type: kUnitTypeExplorer,
          workTarget: kWorkTargetExplore,
        ),
      ],
      tileKeysByRegionAndProvince: {
        WorkAppIds.ow: {
          WorkAppIds.provinceId: [WorkAppIds.tileKey],
        },
      },
    ),
    workAppProcessWorkOrders(),
  );
  expect(
    next.worldState.playerVisibilityByTile['p1']?[WorkAppIds.tileKey],
    VisibilityLevel.fullyVisible.name,
  );
}

void _exploreCompletionRevealsEveryTileInCanonicalFullIdBucket() {
  const tileKey2 = WorkAppIds.originTileKey;
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [
        workAppWorkingUnit(
          type: kUnitTypeExplorer,
          workTarget: kWorkTargetExplore,
        ),
      ],
      tileKeysByRegionAndProvince: const {
        WorkAppIds.ow: {
          WorkAppIds.provinceId: [WorkAppIds.tileKey, tileKey2],
          'P1': ['oldWorld|P1|9|9'],
        },
      },
      playerVisibilityByTile: const {
        'p1': {
          WorkAppIds.tileKey: 'fogged',
          tileKey2: 'unknown',
          'oldWorld|P1|9|9': 'unknown',
        },
      },
    ),
    workAppProcessWorkOrders(),
  );
  expect(
    next.worldState.playerVisibilityByTile['p1']?[WorkAppIds.tileKey],
    VisibilityLevel.fullyVisible.name,
  );
  expect(
    next.worldState.playerVisibilityByTile['p1']?[tileKey2],
    VisibilityLevel.fullyVisible.name,
  );
  expect(
    next.worldState.playerVisibilityByTile['p1']?['oldWorld|P1|9|9'],
    VisibilityLevel.unknown.name,
  );
}

void _buildRoadCompletionIncreasesRoadLevel() {
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [
        workAppWorkingUnit(
          type: kUnitTypeEngineer,
          workTarget: kWorkTargetBuildRoad,
        ),
      ],
      tileState: TileMapState().setRoadLevel(WorkAppIds.tileKey, 0),
    ),
    workAppProcessWorkOrders(),
    tileMapByRegion: const {},
  );
  expect(next.worldState.tileState.roadLevel(WorkAppIds.tileKey), 1);
}

void
_buildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade() {
  const capitalTileKey = WorkAppIds.originTileKey;
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [
        workAppWorkingUnit(
          type: kUnitTypeEngineer,
          workTarget: kWorkTargetBuildRoad,
        ),
      ],
      tileState: TileMapState()
          .setRoadLevel(WorkAppIds.tileKey, 0)
          .setRoadLevel(capitalTileKey, 2),
      players: [
        workAppPlayer(
          capitalProvinceId: WorkAppIds.provinceId,
          capitalTile: const CapitalTile(
            regionId: WorkAppIds.ow,
            provinceId: WorkAppIds.provinceId,
            x: 1,
            y: 0,
          ),
        ),
      ],
    ),
    workAppProcessWorkOrders(),
    tileMapByRegion: {WorkAppIds.ow: workAppSimpleTileMap()},
  );

  // Road built on target tile.
  expect(next.worldState.tileState.roadLevel(WorkAppIds.tileKey), 1);
  // Capital tile was already at level 2 and should remain 2 (no downgrade).
  expect(next.worldState.tileState.roadLevel(capitalTileKey), 2);
}

void
_buildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt() {
  const portTileKey = WorkAppIds.originTileKey;
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [
        workAppWorkingUnit(
          type: kUnitTypeEngineer,
          workTarget: kWorkTargetBuildRoad,
        ),
      ],
      tileState: TileMapState()
          .setRoadLevel(WorkAppIds.tileKey, 1)
          .setRoadLevel(portTileKey, 1),
      portsByProvinceSeaboard: const {
        '${WorkAppIds.provinceId}|sea1': portTileKey,
      },
      players: [
        workAppPlayer(techUnlocked: const {kTechIdRoadConstruction: true}),
      ],
    ),
    workAppProcessWorkOrders(),
    tileMapByRegion: {WorkAppIds.ow: workAppSimpleTileMap()},
  );

  // Road on target tile upgraded from 1 -> 2.
  expect(next.worldState.tileState.roadLevel(WorkAppIds.tileKey), 2);
  // Adjacent port tile upgraded from 1 -> 2.
  expect(next.worldState.tileState.roadLevel(portTileKey), 2);
}

void _buildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea() {
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'P1',
        regionId: WorkAppIds.ow,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'sea1',
        regionId: WorkAppIds.ow,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: const [TopologyEdge(id1: 'P1', id2: 'sea1')],
  );
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [
        workAppWorkingUnit(
          type: kUnitTypeEngineer,
          workTarget: kWorkTargetBuildPort,
        ),
      ],
    ),
    workAppProcessWorkOrders(),
    topology: topology,
  );
  expect(next.worldState.tileState.roadLevel(WorkAppIds.tileKey), 4);
  expect(
    next.worldState.portsByProvinceSeaboard.keys.any(
      (k) => k.startsWith(WorkAppIds.provinceId),
    ),
    isTrue,
  );
}

void _buildFortCompletionIncreasesProvinceFortLevel() {
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [
        workAppWorkingUnit(
          type: kUnitTypeEngineer,
          workTarget: kWorkTargetBuildFort,
        ),
      ],
      provinces: [workAppOwnedProvince(fortLevel: 0)],
    ),
    workAppProcessWorkOrders(),
  );
  expect(next.worldState.oldWorld.provinces.single.fortLevel, 1);
}
