part of 'work_completion_expectation_shorthand.dart';

void wccExpectRailCompletionSetsRoadLevelTo4WhenValid() {
  final next = wccApply(
    wccRailGame(roadLevel: 1, players: wccSteamPlayers()),
    tileMapByRegion: {WorkAppIds.ow: workAppRailMap()},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 4);
}

void wccExpectRailDispatchSetsRoadLevel({
  required int roadLevel,
  required List<Player> players,
  required int expectedLevel,
}) {
  final (state, unit, cw) = wccDispatchRailSetup(
    roadLevel: roadLevel,
    players: players,
  );
  final next = wccDispatchCompleted(state, unit, cw);
  wccExpectRoadLevelOn(next.work.tileState, WorkAppIds.tileKey, expectedLevel);
}

void wccExpectUpgradeTownProvinceLevel({int before = 0, int after = 1}) {
  final unit = workAppUnit(type: kUnitTypeBuilder, status: UnitStatus.working);
  final province = Province(
    id: WorkAppIds.provinceId,
    regionId: WorkAppIds.ow,
    ownerId: 'p1',
    townDevelopmentLevel: before,
  );
  final game = wccGame(
    turnNumber: 1,
    units: [unit],
    provinces: [province],
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
    oldProvinces: [province],
  );
  final next = wccDispatchCompleted(state, u, work);
  expect(next.work.oldProvinces.single.townDevelopmentLevel, after);
}

void wccExpectExploreDispatchCapturesRegion({
  String expectedRegion = WorkAppIds.ow,
}) {
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
  expect(capturedRegionId, expectedRegion);
  expect(identical(next, state), isTrue);
}

void wccExpectRailDispatchSteamAccepted() {
  wccExpectRailDispatchSetsRoadLevel(
    roadLevel: 1,
    players: wccSteamPlayers(),
    expectedLevel: 4,
  );
}

void wccExpectRailDispatchRejectedWithoutRoad() {
  wccExpectRailDispatchSetsRoadLevel(
    roadLevel: 0,
    players: [workAppPlayer()],
    expectedLevel: 0,
  );
}

