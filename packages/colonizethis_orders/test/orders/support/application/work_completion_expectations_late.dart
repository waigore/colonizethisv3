part of 'work_completion_expectations.dart';

void wccLateExploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord() {
      final exploreUnit =
          workAppUnit(type: kUnitTypeExplorer, status: UnitStatus.working);
        final exploreGame = workAppOwnedGame(
          turnNumber: 1,
          units: [exploreUnit],
          provinces: const [],
        );
        const exploreCw = CurrentWork(
          workTarget: kWorkTargetExplore,
          tileKey: WorkAppIds.tileKey,
          totalTurns: 1,
          remainingTurns: 0,
        );
        final (exploreState, exploreU, exploreWork) = wccDispatchWorkSetup(
          unit: exploreUnit,
          game: exploreGame,
          cw: exploreCw,
          oldProvinces: const [],
        );
        String? capturedRegionId;
        final exploreNext = wccDispatchCompleted(
          exploreState,
          exploreU,
          exploreWork,
          onExploreRegion: (s, unit, regionId) {
            capturedRegionId = regionId;
            return s;
          },
        );
        expect(capturedRegionId, WorkAppIds.ow);
        expect(identical(exploreNext, exploreState), isTrue);
}
