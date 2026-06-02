import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart';
import 'package:colonizethis_ai/src/planning/goal_manager.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('prepareConquestFieldArmy', () {
    test('splits regiments from home army when pursuing conquer', () {
      const cap = 'oldWorld|cap';
      var game = Game(
        id: 'g_prep',
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
        oldWorldProvincesOwned: 10,
        primaryGoal: StrategicGoal.conquer,
      );

      final home = game.worldState.armies
          .singleWhere((a) => a.id == homeArmyIdFor('gp1'));
      final field = game.worldState.armies
          .where((a) => a.ownerId == 'gp1' && !a.isHomeArmy)
          .toList();
      expect(home.regimentUnitIds.length, 2);
      expect(field.length, 1);
      expect(field.single.regimentUnitIds.length, 1);
      expect(field.single.isHomeArmy, isFalse);
    });

    test('no-op when field army already has regiments at capital', () {
      const cap = 'oldWorld|cap';
      final game = Game(
        id: 'g_prep2',
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
            Army(
              id: 'army_field',
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: cap,
              regimentUnitIds: const ['u4'],
              isHomeArmy: false,
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
        oldWorldProvincesOwned: 10,
        primaryGoal: StrategicGoal.conquer,
      );

      expect(after.worldState.armies.length, game.worldState.armies.length);
    });

    // Stalled-expansion multi-split path (Refs #2509 § Field army prep,
    // SPEC/ai/ai-architecture.md). When OW expansion is stalled
    // (`oldWorldProvincesOwned <= kStalledOldWorldProvinceThreshold = 9`),
    // `prepareConquestFieldArmy` repeats `applyArmySplit` so the planner can
    // commit parallel field armies to multiple invadable OW frontiers in the
    // same turn instead of marching only one army per turn. The existing
    // tests above pin the single-split + no-op branches; the cases below
    // pin the stalled-branch contract (loop count, regiment distribution,
    // and the cap guard from `kStalledConquestFieldArmySplitCap`).
    test('stalled multi-split: home army with 6 regiments splits repeatedly '
        'until home has 1 regiment', () {
      const cap = 'oldWorld|cap';
      var game = Game(
        id: 'g_prep_stalled_multi',
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
              regimentUnitIds: const ['u1', 'u2', 'u3', 'u4', 'u5', 'u6'],
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
      // 6 → split 3 → home 3 + field 3
      // 3 → split 1 → home 2 + field 1
      // 2 → split 1 → home 1 + field 1
      // 1 → break (length < 2)
      expect(
        home.regimentUnitIds.length,
        1,
        reason:
            'Stalled multi-split should reduce the Home Army to 1 regiment '
            '(loop breaks at length < 2).',
      );
      expect(
        fields.length,
        3,
        reason: 'Three field armies should be created from a 6-regiment '
            'Home Army when stalled (6 → 3 → 1 → 1).',
      );
      final totalFieldRegiments = fields.fold<int>(
        0,
        (sum, a) => sum + a.regimentUnitIds.length,
      );
      expect(
        totalFieldRegiments,
        5,
        reason: '5 of 6 regiments should move into field armies; 1 remains '
            'in the Home Army.',
      );
      for (final field in fields) {
        expect(field.stationedProvinceId, cap);
        expect(field.regionId, 'oldWorld');
        expect(field.isHomeArmy, isFalse);
      }
    });

    test('stalled multi-split: with existing field army at capital, the '
        'loop continues splitting from i = fieldArmiesAtCapital up to the '
        'cap', () {
      const cap = 'oldWorld|cap';
      var game = Game(
        id: 'g_prep_stalled_with_field',
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
              regimentUnitIds: const ['u1', 'u2', 'u3', 'u4'],
              isHomeArmy: true,
            ),
            Army(
              id: 'army_existing_field',
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: cap,
              regimentUnitIds: const ['u_pre'],
              isHomeArmy: false,
            ),
          ],
          nextArmySeq: 3,
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
        home.regimentUnitIds.length,
        1,
        reason: 'Stalled split continues until the Home Army has 1 regiment.',
      );
      expect(
        fields.length,
        greaterThanOrEqualTo(2),
        reason: 'At least one additional field army should be created on top '
            'of the existing field army when stalled.',
      );
      final existing = fields.singleWhere((a) => a.id == 'army_existing_field');
      expect(
        existing.regimentUnitIds,
        const ['u_pre'],
        reason: 'The pre-existing field army should not be re-split or merged.',
      );
    });

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
