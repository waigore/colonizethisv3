// Topic-split pins from `treasury_planner_core_budget_cases.dart` (Refs #4669 Slice D).

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void registerTreasuryPlannerCoreBudgetLockRecoveryTailCases() {
  group('runTreasuryPlanner(TreasuryPlannerInput(Refs #2994))', () {
    test(
      'below-quota zero-NW affluent GP is excluded from designated buyer '
      'pool (Refs #2924 Path F)',
      () {
        const ow = 'oldWorld';
        final game = Game(
          id: 'g-lock-recovery-seller',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 7; i++)
                  Province(
                    id: '$ow|p2_$i',
                    regionId: ow,
                    ownerId: 'gp2',
                  ),
                Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(
              id: 'gp1',
              displayName: 'GP1',
              isHuman: false,
              capitalProvinceId: '$ow|p1',
              treasury: 0,
            ),
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              capitalProvinceId: '$ow|p2_0',
              treasury: 2500,
            ),
          ],
        );
        expect(
          lockRecoveryDesignatedBuyerId(game),
          isEmpty,
          reason: 'gp2 is affluent but below quota with zero NW — must stay '
              'sell-only until Path F credits accumulate.',
        );
      },
    );
  });
}
