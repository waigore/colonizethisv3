// Table-driven privateering intercept scenarios (Refs #3865, #3470).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

/// One row in a naval privateering scenario table.
class NavalCombatPrivateeringScenario {
  const NavalCombatPrivateeringScenario({
    required this.scenarioId,
    required this.label,
    required this.run,
  });

  final String scenarioId;
  final String label;
  final void Function() run;
}

/// Runs [scenario] (setup + assertions live in [NavalCombatPrivateeringScenario.run]).
void runNavalCombatPrivateeringScenario(
  NavalCombatPrivateeringScenario scenario,
) {
  scenario.run();
}

Game _gameWithInterceptorTech({required bool hasPrivateering}) =>
    TestFixtures.minimalGame(
      id: 'g1',
      players: [
        const Player(id: 'p1', displayName: 'Mover', isHuman: true),
        Player(
          id: 'p2',
          displayName: 'Interceptor',
          isHuman: false,
          techUnlocked: hasPrivateering
              ? const {kTechIdPrivateeringCompanies: true}
              : const {},
        ),
      ],
      fleets: [
        Fleet(
          id: 'mover_p1',
          ownerId: 'p1',
          seaZoneId: 'sea1',
          regionId: 'oldWorld',
          shipTypeIds: const ['fluyte'],
        ),
      ],
    );

List<BattleContextSea> _battlesFor(Game game) => [
  BattleContextSea(
    seaZoneId: 'sea1',
    side1: NavalBattleSide(
      ownerId: 'p1',
      ships: legacyShipInstancesForFleet('mover_p1', const ['fluyte']),
    ),
    side2: NavalBattleSide(
      ownerId: 'p2',
      ships: legacyShipInstancesForFleet('patrol_p2', const ['sloop']),
      mission: FleetMission.blockade,
    ),
  ),
];

int _countIntercepts({required bool hasPrivateering}) {
  final game = _gameWithInterceptorTech(hasPrivateering: hasPrivateering);
  final battles = _battlesFor(game);
  var intercepts = 0;
  for (var seed = 0; seed < 200; seed++) {
    final out = filterBattlesByInterception(
      game,
      battles,
      {'mover_p1'},
      seed,
    );
    if (out.isNotEmpty) intercepts++;
  }
  return intercepts;
}

List<NavalCombatPrivateeringScenario>
    navalPrivateeringInterceptProbabilityScenarios() => [
  NavalCombatPrivateeringScenario(
    scenarioId: 'npp-baseline',
    label: 'no privateering uses the baseline (unscaled) interceptor score',
    run: () {
      expect(
        navalInterceptProbability(
          interceptorScore: 5,
          targetFleeScore: 5,
          isBlockade: false,
        ),
        0.25,
      );
    },
  ),
  NavalCombatPrivateeringScenario(
    scenarioId: 'npp-scaled',
    label: 'privateering scales interceptor score by 1.25 before clamp',
    run: () {
      expect(
        navalInterceptProbability(
          interceptorScore: 5,
          targetFleeScore: 5,
          isBlockade: false,
          interceptorHasPrivateering: true,
        ),
        closeTo(6.25 / 11.25 * 0.5, 1e-9),
      );
    },
  ),
  NavalCombatPrivateeringScenario(
    scenarioId: 'npp-higher-than-baseline',
    label: 'privateering yields strictly higher probability than baseline',
    run: () {
      final baseline = navalInterceptProbability(
        interceptorScore: 5,
        targetFleeScore: 5,
        isBlockade: true,
      );
      final boosted = navalInterceptProbability(
        interceptorScore: 5,
        targetFleeScore: 5,
        isBlockade: true,
        interceptorHasPrivateering: true,
      );
      expect(boosted, greaterThan(baseline));
    },
  ),
  NavalCombatPrivateeringScenario(
    scenarioId: 'npp-clamped',
    label: 'privateering result remains within [0.05, 0.85] clamp',
    run: () {
      final p = navalInterceptProbability(
        interceptorScore: 1000,
        targetFleeScore: 1,
        isBlockade: true,
        interceptorHasPrivateering: true,
      );
      expect(p, lessThanOrEqualTo(0.85));
      expect(p, greaterThanOrEqualTo(0.05));
    },
  ),
];

List<NavalCombatPrivateeringScenario>
    filterBattlesByInterceptionPrivateeringScenarios() => [
  NavalCombatPrivateeringScenario(
    scenarioId: 'fbi-at-least-as-often',
    label: 'interceptor with privateering intercepts at least as often',
    run: () {
      final withTech = _countIntercepts(hasPrivateering: true);
      final withoutTech = _countIntercepts(hasPrivateering: false);
      expect(withTech, greaterThan(withoutTech));
    },
  ),
  NavalCombatPrivateeringScenario(
    scenarioId: 'fbi-deterministic',
    label: 'interception counts are deterministic for fixed seeds',
    run: () {
      expect(
        _countIntercepts(hasPrivateering: true),
        _countIntercepts(hasPrivateering: true),
      );
    },
  ),
];
