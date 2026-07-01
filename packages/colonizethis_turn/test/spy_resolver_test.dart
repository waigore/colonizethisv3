import 'dart:math';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/src/turn/spy_resolver.dart';

void main() {
  group('resolveSpyPhase', () {
    test('base 5% kill chance with zero garrison', () {
      final game = _gameWithForeignSpy(garrisonRegiments: 0, seed: 1);
      var kills = 0;
      for (var i = 0; i < 200; i++) {
        final result = resolveSpyPhase(game, random: Random(i));
        if (result.killedSpyUnitIds.isNotEmpty) kills++;
      }
      expect(kills, greaterThan(0));
      expect(kills, lessThan(200));
    });

    test('garrison augments kill chance', () {
      final low = _countKills(_gameWithForeignSpy(garrisonRegiments: 0, seed: 7));
      final high = _countKills(_gameWithForeignSpy(garrisonRegiments: 8, seed: 7));
      expect(high, greaterThan(low));
    });

    test('empire-wide counter-espionage adds kill bonus', () {
      final without = _countKills(
        _gameWithForeignSpy(
          garrisonRegiments: 0,
          ownerRunsCounterSpy: false,
          seed: 42,
        ),
      );
      final withCounter = _countKills(
        _gameWithForeignSpy(
          garrisonRegiments: 0,
          ownerRunsCounterSpy: true,
          seed: 42,
        ),
      );
      expect(withCounter, greaterThan(without));
    });

    test('records caught spy details when killed', () {
      final game = _gameWithForeignSpy(garrisonRegiments: 8, seed: 99);
      for (var i = 0; i < 500; i++) {
        final result = resolveSpyPhase(game, random: Random(i));
        if (result.caughtSpies.isEmpty) continue;
        final caught = result.caughtSpies.single;
        expect(caught.unitId, 'spy_enemy');
        expect(caught.spyOwnerId, 'gp2');
        expect(caught.territoryOwnerId, 'gp1');
        expect(caught.provinceId, 'oldWorld|p2');
        return;
      }
      fail('expected at least one kill in 500 trials with max garrison');
    });
  });

  group('applySpyResearchBoostToPoints', () {
    test('applies +15% per qualifying rival GP', () {
      expect(
        applySpyResearchBoostToPoints(basePoints: 100, qualifyingRivalGpCount: 1),
        115,
      );
      expect(
        applySpyResearchBoostToPoints(basePoints: 100, qualifyingRivalGpCount: 2),
        130,
      );
    });
  });
}

int _countKills(Game game, {int trials = 200}) {
  var kills = 0;
  for (var i = 0; i < trials; i++) {
    if (resolveSpyPhase(game, random: Random(i)).killedSpyUnitIds.isNotEmpty) {
      kills++;
    }
  }
  return kills;
}

Game _gameWithForeignSpy({
  required int garrisonRegiments,
  bool ownerRunsCounterSpy = false,
  required int seed,
}) {
  const ow = 'oldWorld';
  const p1 = '$ow|p1';
  const p2 = '$ow|p2';
  const tile = '$p2|0|0';
  final foreignSpy = Unit(
    id: 'spy_enemy',
    type: kUnitTypeSpy,
    ownerId: 'gp2',
    locationProvinceId: p2,
    tileKey: tile,
  );
  final counterSpy = ownerRunsCounterSpy
      ? Unit(
          id: 'spy_own',
          type: kUnitTypeSpy,
          ownerId: 'gp1',
          locationProvinceId: p1,
          tileKey: '$p1|0|0',
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: 'counter_spy',
            tileKey: '$p1|0|0',
            totalTurns: 0,
            remainingTurns: 1,
          ),
        )
      : null;
  final units = <Unit>[foreignSpy, if (counterSpy != null) counterSpy];
  final armies = garrisonRegiments == 0
      ? const <Army>[]
      : [
          Army(
            id: 'army1',
            ownerId: 'gp1',
            regionId: ow,
            stationedProvinceId: p2,
            regimentUnitIds: List.generate(
              garrisonRegiments,
              (i) => 'reg_$i',
            ),
          ),
        ];
  return Game(
    id: 'g',
    globalGameSeed: seed,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
      oldWorld: RegionData(
        provinces: const [
          Province(id: p1, regionId: ow, ownerId: 'gp1'),
          Province(id: p2, regionId: ow, ownerId: 'gp1'),
        ],
        units: units,
      ),
      newWorld: const RegionData(),
      armies: armies,
    ),
    players: const [
      Player(id: 'gp1', displayName: 'GP1', isHuman: true),
      Player(id: 'gp2', displayName: 'GP2', isHuman: false),
    ],
  );
}
