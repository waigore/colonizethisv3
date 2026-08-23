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

void registerArmyConquestPrepStalledSplitCasesTail() {
  group('prepareConquestFieldArmy', () {
    // Stalled-expansion multi-split path (Refs #2509 § Field army prep,
    // SPEC/ai/ai-architecture.md). When OW expansion is stalled
    // (`oldWorldProvincesOwned <= kStalledOldWorldProvinceThreshold = 9`),
    // `prepareConquestFieldArmy` repeats `applyArmySplit` so the planner can
    // commit parallel field armies to multiple invadable OW frontiers in the
    // same turn instead of marching only one army per turn. The existing
    // tests above pin the single-split + no-op branches; the cases below
    // pin the stalled-branch contract (loop count, regiment distribution,
    // and the cap guard from `kStalledConquestFieldArmySplitCap`).
    test('stalled split respects kStalledConquestFieldArmySplitCap', () {
      const cap = 'oldWorld|cap';
      final homeRegs = List<String>.generate(
        2 * kStalledConquestFieldArmySplitCap + 2,
        (i) => 'u${i + 1}',
      );
      var game = Game(
        id: 'g_prep_stalled_cap',
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
              regimentUnitIds: homeRegs,
              isHomeArmy: true,
            ),
          ],
          nextArmySeq: 2,
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

      game = prepareConquestFieldArmy(
        game: game,
        nationId: 'gp1',
        provincesToVictory: 24,
        oldWorldProvincesOwned: 5,
        primaryGoal: StrategicGoal.expand,
      );

      final fields = game.worldState.armies
          .where((a) => a.ownerId == 'gp1' && !a.isHomeArmy)
          .toList();
      expect(
        fields.length,
        lessThanOrEqualTo(kStalledConquestFieldArmySplitCap),
        reason:
            'Stalled split must not exceed kStalledConquestFieldArmySplitCap '
            '(= $kStalledConquestFieldArmySplitCap) field armies even when the '
            'Home Army has enough regiments for more splits.',
      );
    });

    // Sole-regiment auto-split path (Refs #2925). Pre-#2925 this case was a
    // no-op because the multi-split loop's `length < 2` guard skipped it,
    // leaving the sole regiment in the Home Army where army-move suggestions
    // (which always exclude `isHomeArmy`) could never reach it. Approach C
    // peels the lone regiment out into a new non-Home field army at the
    // capital so the existing army-move paths can issue a march.
    test('stalled split: home army with sole regiment is peeled into a '
        'new field army leaving the Home Army empty (Refs #2925)', () {
      const cap = 'oldWorld|cap';
      var game = Game(
        id: 'g_prep_stalled_one_reg',
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
          nextArmySeq: 2,
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

      game = prepareConquestFieldArmy(
        game: game,
        nationId: 'gp1',
        provincesToVictory: 24,
        oldWorldProvincesOwned: 5,
        primaryGoal: StrategicGoal.expand,
      );

      final home = game.worldState.armies
          .singleWhere((a) => a.id == homeArmyIdFor('gp1'));
      final fields = game.worldState.armies
          .where((a) => a.ownerId == 'gp1' && !a.isHomeArmy)
          .toList();
      expect(
        home.regimentUnitIds,
        isEmpty,
        reason: 'Sole regiment splits out of the Home Army; SPEC-permitted '
            'empty Home Army per SPEC/game/military-armies.md § Home Army → '
            'Persistence.',
      );
      expect(
        home.isHomeArmy,
        isTrue,
        reason: 'Home Army is never deleted when empty.',
      );
      expect(
        fields.length,
        1,
        reason: 'Exactly one new field army is created at the capital '
            '(SPEC/ai/phase-planner-architecture.md § AI conquest-prep '
            'auto-split — sole-regiment row).',
      );
      expect(fields.single.regimentUnitIds, const ['u_only']);
      expect(fields.single.stationedProvinceId, cap);
      expect(fields.single.regionId, 'oldWorld');
      expect(fields.single.isHomeArmy, isFalse);
    });

    // Negative regression guard (Refs #2925): the sole-regiment split is
    // gated on the stalled-expansion predicate. When the GP is not stalled
    // and no conquest pace pressure exists, the auto-split must remain a
    // no-op so casual EXPAND/COLONIAL/DEVELOP turns do not silently
    // restructure the Home Army.
  });
}
