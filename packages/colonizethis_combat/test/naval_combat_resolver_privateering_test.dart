import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Privateering interception bonus (Slice B of #3470).
/// SPEC/program/naval-movement-resolution.md § Interception;
/// SPEC/game/tech-tree-naval.md (`privateering_companies`).
void main() {
  group('navalInterceptProbability privateering bonus', () {
    test('no privateering uses the baseline (unscaled) interceptor score', () {
      // Ratio = 5/(5+5) = 0.5, patrol factor = 0.5 => 0.25.
      expect(
        navalInterceptProbability(
          interceptorScore: 5,
          targetFleeScore: 5,
          isBlockade: false,
        ),
        0.25,
      );
    });

    test('privateering scales interceptor score by 1.25 before clamp', () {
      // 5 * 1.25 = 6.25; ratio = 6.25/(6.25+5) = 0.5556; * 0.5 = 0.2778.
      expect(
        navalInterceptProbability(
          interceptorScore: 5,
          targetFleeScore: 5,
          isBlockade: false,
          interceptorHasPrivateering: true,
        ),
        closeTo(6.25 / 11.25 * 0.5, 1e-9),
      );
    });

    test('privateering yields strictly higher probability than baseline', () {
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
    });

    test('privateering result remains within [0.05, 0.85] clamp', () {
      final p = navalInterceptProbability(
        interceptorScore: 1000,
        targetFleeScore: 1,
        isBlockade: true,
        interceptorHasPrivateering: true,
      );
      expect(p, lessThanOrEqualTo(0.85));
      expect(p, greaterThanOrEqualTo(0.05));
    });
  });

  group('filterBattlesByInterception privateering wiring', () {
    Game gameWithInterceptorTech({required bool hasPrivateering}) => Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
        fleets: [
          Fleet(
            id: 'mover_p1',
            ownerId: 'p1',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: const ['fluyte'],
          ),
        ],
      ),
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
    );

    List<BattleContextSea> battlesFor(Game game) => [
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

    int countIntercepts({required bool hasPrivateering}) {
      final game = gameWithInterceptorTech(hasPrivateering: hasPrivateering);
      final battles = battlesFor(game);
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

    test('interceptor with privateering intercepts at least as often', () {
      final withTech = countIntercepts(hasPrivateering: true);
      final withoutTech = countIntercepts(hasPrivateering: false);
      expect(withTech, greaterThan(withoutTech));
    });

    test('interception counts are deterministic for fixed seeds', () {
      expect(
        countIntercepts(hasPrivateering: true),
        countIntercepts(hasPrivateering: true),
      );
    });
  });
}
