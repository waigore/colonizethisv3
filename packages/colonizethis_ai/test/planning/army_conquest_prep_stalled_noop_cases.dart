// Case bodies for `army_conquest_prep_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Stalled-expansion prepareConquestFieldArmy pins for `army_conquest_prep_test.dart`.
// Multi-split, cap guard, sole-regiment peel, and negative guards.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart';
import 'package:colonizethis_ai/src/planning/goal_manager.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void registerArmyConquestPrepStalledNoopCases() {
  group('prepareConquestFieldArmy', () {
    test('non-stalled no-op: home army with sole regiment is not split when '
        'stalled=false, primaryGoal!=conquer, and provincesToVictory below '
        'the pace threshold (Refs #2925)', () {
      const cap = 'oldWorld|cap';
      final game = Game(
        id: 'g_prep_non_stalled_one_reg',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: cap,
                regionId: 'oldWorld',
                ownerId: 'gp1',
                townTileKey: 'oldWorld|cap|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(provinces: [], units: []),
          armies: [
            Army(
              id: homeArmyIdFor('gp1'),
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: cap,
              regimentUnitIds: const ['u_only'],
              isHomeArmy: true,
            ),
          ],
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP',
            isHuman: false,
            leaderKey: 'napoleon',
            capitalProvinceId: cap,
          ),
        ],
      );

      final after = prepareConquestFieldArmy(
        game: game,
        nationId: 'gp1',
        provincesToVictory: kBuildRegimentVictoryPaceThreshold,
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold + 1,
        primaryGoal: StrategicGoal.expand,
      );

      expect(
        after.worldState.armies,
        game.worldState.armies,
        reason: 'Non-stalled, non-conquer, below-pace: the `length < 2` no-op '
            'floor remains in effect (Refs #2925 negative regression guard).',
      );
    });

    test('no-op when home army has 0 regiments', () {
      const cap = 'oldWorld|cap';
      final game = Game(
        id: 'g_prep_zero_home',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: cap,
                regionId: 'oldWorld',
                ownerId: 'gp1',
                townTileKey: 'oldWorld|cap|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(provinces: [], units: []),
          armies: [
            Army(
              id: homeArmyIdFor('gp1'),
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: cap,
              regimentUnitIds: const [],
              isHomeArmy: true,
            ),
          ],
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP',
            isHuman: false,
            leaderKey: 'napoleon',
            capitalProvinceId: cap,
          ),
        ],
      );

      final after = prepareConquestFieldArmy(
        game: game,
        nationId: 'gp1',
        provincesToVictory: 24,
        oldWorldProvincesOwned: 5,
        primaryGoal: StrategicGoal.expand,
      );

      expect(after.worldState.armies, game.worldState.armies);
    });

    test('shouldPrep false: not stalled, not conquer, provincesToVictory '
        'below pace threshold → no-op', () {
      const cap = 'oldWorld|cap';
      final game = Game(
        id: 'g_prep_no_should_prep',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: cap,
                regionId: 'oldWorld',
                ownerId: 'gp1',
                townTileKey: 'oldWorld|cap|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(provinces: [], units: []),
          armies: [
            Army(
              id: homeArmyIdFor('gp1'),
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: cap,
              regimentUnitIds: const ['u1', 'u2', 'u3'],
              isHomeArmy: true,
            ),
          ],
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP',
            isHuman: false,
            leaderKey: 'napoleon',
            capitalProvinceId: cap,
          ),
        ],
      );

      final after = prepareConquestFieldArmy(
        game: game,
        nationId: 'gp1',
        provincesToVictory: kBuildRegimentVictoryPaceThreshold,
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold + 1,
        primaryGoal: StrategicGoal.expand,
      );

      expect(
        after.worldState.armies,
        game.worldState.armies,
        reason:
            'When primaryGoal != conquer, provincesToVictory <= pace '
            'threshold, and oldWorldProvincesOwned is above the stalled '
            'threshold, no split should occur.',
      );
    });
  });
}
