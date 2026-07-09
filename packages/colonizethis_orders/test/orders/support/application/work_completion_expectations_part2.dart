part of 'work_completion_expectations.dart';

void _buildRailCompletionLeavesRoadWhenTileHasNoRoad() {
  final next = wccApply(
    wccRailGame(
      roadLevel: 0,
      players: [
        workAppPlayer(techUnlocked: const {kTechIdEarlySteamEngine: true}),
      ],
    ),
    tileMapByRegion: {WorkAppIds.ow: workAppRailMap()},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 0);
}

void _buildRailCompletionSetsRoadLevelTo4WhenValid() {
  final next = wccApply(
    wccRailGame(
      roadLevel: 1,
      players: [
        workAppPlayer(techUnlocked: const {kTechIdEarlySteamEngine: true}),
      ],
    ),
    tileMapByRegion: {WorkAppIds.ow: workAppRailMap()},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 4);
}

void _routesKWorkTargetBuildRailThroughHandlerMapEntry() {
  final (state, unit, cw) = wccDispatchRailSetup(
    roadLevel: 1,
    players: [
      workAppPlayer(techUnlocked: const {kTechIdEarlySteamEngine: true}),
    ],
  );
  final next = wccDispatchCompleted(state, unit, cw);
  wccExpectRoadLevelOn(next.work.tileState, WorkAppIds.tileKey, 4);
}

void _buildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies() {
  final (state, unit, cw) = wccDispatchRailSetup(
    roadLevel: 0,
    players: [workAppPlayer()],
  );
  final next = wccDispatchCompleted(state, unit, cw);
  wccExpectRoadLevelOn(next.work.tileState, WorkAppIds.tileKey, 0);
}

void _upgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord() {
  final unit = workAppUnit(type: kUnitTypeBuilder, status: UnitStatus.working);
  const province = Province(
    id: WorkAppIds.provinceId,
    regionId: WorkAppIds.ow,
    ownerId: 'p1',
    townDevelopmentLevel: 0,
  );
  final game = wccGame(
    turnNumber: 1,
    units: [unit],
    provinces: const [province],
  );
  const cw = CurrentWork(
    workTarget: kWorkTargetUpgradeTown,
    tileKey: WorkAppIds.tileKey,
    totalTurns: 1,
    remainingTurns: 0,
  );
  final (state, u, work) = wccDispatchWorkSetup(
    unit: unit,
    game: game,
    cw: cw,
    oldProvinces: const [province],
  );
  final next = wccDispatchCompleted(state, u, work);
  expect(next.work.oldProvinces.single.townDevelopmentLevel, 1);
}

void _exploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord() {
  final unit = workAppUnit(type: kUnitTypeExplorer, status: UnitStatus.working);
  final game = workAppOwnedGame(
    turnNumber: 1,
    units: [unit],
    provinces: const [],
  );
  const cw = CurrentWork(
    workTarget: kWorkTargetExplore,
    tileKey: WorkAppIds.tileKey,
    totalTurns: 1,
    remainingTurns: 0,
  );
  final (state, u, work) = wccDispatchWorkSetup(
    unit: unit,
    game: game,
    cw: cw,
    oldProvinces: const [],
  );
  String? capturedRegionId;
  final next = wccDispatchCompleted(
    state,
    u,
    work,
    onExploreRegion: (s, unit, regionId) {
      capturedRegionId = regionId;
      return s;
    },
  );
  expect(capturedRegionId, WorkAppIds.ow);
  expect(identical(next, state), isTrue);
}
