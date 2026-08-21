// resolveDiplomacyPhase join-empire + part2 scenarios (Refs #4574).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';
import 'diplomacy_game_fixtures_scenarios.dart';
import 'diplomacy_phase_scenarios.dart';
import 'diplomacy_resolver_phase_scenario_helpers.dart';
import 'diplomacy_resolver_phase_scenarios.dart';

List<DiplomacyPhaseScenario> diplomacyResolverPhasePart1JoinEmpireScenarios() => [
  dpsRow(
    'join empire absorbs minor: provinces transfer, minor removed, cost deducted',
    () {
      final after = dpsResolve(
        dpsJoinEmpireGame(WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [dpsOwProv('m1'), dpsOwProv('m2')], units: []),
          newWorld: const RegionData(),
        )),
        dpsDip('gp1', dpsJoinEmpireMinor1),
      );
      expect(after.minorNations.any((m) => m.id == 'minor1'), isFalse);
      expect(getOverture(after, 'gp1', 'minor1'), isNull);
      expect(dpsOwOwner(after, 'm1'), 'gp1');
      expect(dpsOwOwner(after, 'm2'), 'gp1');
      expect(after.playerById('gp1')!.treasury, 15000 - 9000);
    },
  ),
  dpsRow('join empire clears Spy timers for provinces that become owned by GP', () {
    final after = dpsResolve(
      dpsJoinEmpireGame(const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [Province(id: '$dpsOw|m1', regionId: dpsOw, ownerId: 'minor1')],
          units: [],
        ),
        newWorld: RegionData(),
        playerVisibilityByTile: {'gp1': {'oldWorld|m1|0|0': 'fullyVisible'}},
        spyRevealTurnsByPlayer: {'gp1': {'$dpsOw|m1': 3}},
        tileKeysByRegionAndProvince: {dpsOw: {'$dpsOw|m1': ['oldWorld|m1|0|0']}},
      )),
      dpsDip('gp1', dpsJoinEmpireMinor1),
    );
    expect(dpsOwOwner(after, 'm1'), 'gp1');
    expect(after.worldState.spyRevealTurnsByPlayer['gp1'], isNull);
    expect(
      after.worldState.playerVisibilityByTile['gp1']?['oldWorld|m1|0|0'],
      'fullyVisible',
    );
  }),
];

/// Part 1 scenarios from `diplomacy_resolver_phase_test_part1_test.dart`.
List<DiplomacyPhaseScenario> diplomacyResolverPhasePart1Scenarios() => [
  ...diplomacyResolverPhasePart1WarPeaceScenarios(),
  ...diplomacyResolverPhasePart1GrantAidScenarios(),
  ...diplomacyResolverPhasePart1JoinEmpireScenarios(),
];

void _expectSubsidyResolution(int amount, {required bool valid}) {
  final after = dpsResolve(
    gpMinorEmbassyNeutralPhaseGame(),
    dpsDip('gp1', [
      DiplomaticOrder(
        type: DiplomaticOrderType.setSubsidy,
        targetFactionId: 'minor1',
        amount: amount,
      ),
    ]),
  );
  if (valid) {
    expect(after.subsidyStates, hasLength(1));
    expect(after.subsidyStates.single.percent, amount);
    expect(after.subsidyStates.single.targetId, 'minor1');
  } else {
    expect(after.subsidyStates, isEmpty);
  }
}

/// Part 2 scenarios from `diplomacy_resolver_phase_test_part2_test.dart`.
List<DiplomacyPhaseScenario> diplomacyResolverPhasePart2Scenarios() => [
  dpsRow('returns game when there are no diplomatic orders', () {
    final game = diplomacyResolverPhaseTestBaseGame();
    expect(dpsResolve(game, const Orders()).id, game.id);
  }),
  dpsRow(
    'setSubsidy at resolution with invalid percent is skipped, not thrown '
    '(Refs #3753 R3)',
    () => _expectSubsidyResolution(7, valid: false),
  ),
  dpsRow(
    'setSubsidy at resolution with valid percent records SubsidyState '
    '(Refs #3753 R3)',
    () => _expectSubsidyResolution(10, valid: true),
  ),
];
