// resolveDiplomacyPhase scenarios part1 war/peace/grant (Refs #4574).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

import 'diplomacy_game_fixtures_scenarios.dart';
import 'diplomacy_phase_scenarios.dart';
import 'diplomacy_resolver_phase_scenario_helpers.dart';

List<DiplomacyPhaseScenario> diplomacyResolverPhasePart1WarPeaceScenarios() => [
  dpsRow('overture payments create consulate and embassy when treasury allows', () {
    final after = dpsResolve(diplomacyResolverPhaseTestBaseGame(), dpsDip('gp1', dpsOvertureConsulateEmbassy));
    final overture = getOverture(after, 'gp1', 'minor1');
    expect(overture, isNotNull);
    expect(overture!.hasEmbassy, isTrue);
    expect(after.playerById('gp1')!.treasury, lessThan(2000));
  }),
  dpsRow('alliance order sets relation to allied', () {
    final after = dpsResolve(
      diplomacyGame(id: 'g1', players: const [dpsGp1, dpsGp2]),
      dpsDip('gp1', const [
        DiplomaticOrder(type: DiplomaticOrderType.alliance, targetFactionId: 'gp2'),
      ]),
    );
    final rel = getRelation(after, 'gp1', 'gp2');
    expect(rel, isNotNull);
    expect(rel!.level, RelationLevel.allied);
    expect(rel.score, 76);
  }),
  dpsRow('declare war and offer peace update relation state', () {
    final game = diplomacyResolverPhaseTestBaseGame();
    final afterWar = dpsResolve(game, dpsDip('gp1', dpsDeclareWarMinor1));
    expect(getRelation(afterWar, 'gp1', 'minor1')!.atWar, isTrue);
    final afterPeace = dpsResolve(afterWar, dpsDip('gp1', dpsPeaceMinor1));
    expect(getRelation(afterPeace, 'gp1', 'minor1')!.atPeace, isTrue);
  }),
  dpsRow('declare war when already at peace updates existing relation', () {
    final after = dpsResolve(
      diplomacyResolverPhaseTestBaseGame().copyWith(diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'minor1',
          score: 60,
          level: RelationLevel.friendly,
          state: RelationState.atPeace,
        ),
      ]),
      dpsDip('gp1', dpsDeclareWarMinor1),
    );
    final rel = getRelation(after, 'gp1', 'minor1')!;
    expect(rel.atWar, isTrue);
    expect(rel.score, lessThan(60));
  }),
];

/// Grant-aid scenarios from part 1 integration tests.
List<DiplomacyPhaseScenario> diplomacyResolverPhasePart1GrantAidScenarios() => [
  dpsRow('grantAid requires embassy and improves relations', () {
    final initialRel = gpMinorNeutralRelation();
    final after = dpsResolve(
      dpsGrantAidGame(),
      dpsDip('gp1', const [
        DiplomaticOrder(
          type: DiplomaticOrderType.grantAid,
          targetFactionId: 'minor1',
          amount: 1000,
        ),
      ]),
    );
    final rel = getRelation(after, 'gp1', 'minor1')!;
    expect(rel.score, greaterThan(initialRel.score));
    expect(tradeSlotsForGp(after, 'gp1', 'minor1'), 3);
    expect(after.playerById('gp1')!.treasury, 2000 - 1000);
  }),
  dpsRow('grantAid at resolution with wrong multiple throws StateError', () {
    expect(
      () => dpsResolve(
        dpsGrantAidGame(),
        dpsDip('gp1', const [
          DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 500,
          ),
        ]),
      ),
      throwsStateError,
    );
  }),
];

/// Join-empire scenarios from part 1 integration tests.
