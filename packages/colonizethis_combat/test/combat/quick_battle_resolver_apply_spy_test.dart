import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('applyQuickBattleResultToGame Spy timer interaction', () {
    test('quick battle conquest clears Spy timer for new owner province', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$ow|P1|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: provinceId, regionId: ow, ownerId: 'def'),
            ],
            units: [
              Unit(
                id: 'att1',
                type: 'grenadiers',
                ownerId: 'att',
                locationProvinceId: provinceId,
              ),
              Unit(
                id: 'def1',
                type: 'peasant_levies',
                ownerId: 'def',
                locationProvinceId: provinceId,
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'att': {tileKey: 'fullyVisible'},
          },
          spyRevealTurnsByPlayer: const {
            'att': {provinceId: 3, 'oldWorld|OTHER': 2},
            'def': {provinceId: 3},
            'ally': {provinceId: 4},
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              provinceId: [tileKey],
            },
          },
        ),
        players: const [
          Player(id: 'att', displayName: 'Att', isHuman: true),
          Player(id: 'def', displayName: 'Def', isHuman: true),
        ],
      );

      const ctx = BattleContext(
        provinceId: provinceId,
        regionId: ow,
        defenderFactionId: 'def',
        defenderUnitIds: ['def1'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['att1'], generalMedals: 0),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      const result = QuickBattleResult(
        winner: QuickBattleWinner.attacker,
        attackerCasualties: ['att1'],
        defenderCasualties: ['def1'],
        provinceFlips: true,
      );

      final after = applyQuickBattleResultToGame(game, ctx, result);
      final province = after.worldState.oldWorld.provinces
          .where((p) => p.id == provinceId)
          .first;
      expect(province.ownerId, 'att');

      // Spy timer for (att, provinceId) and (def, provinceId) cleared; other timers remain.
      final attackerTimers =
          after.worldState.spyRevealTurnsByPlayer['att'] ?? const {};
      expect(attackerTimers.containsKey(provinceId), isFalse);
      expect(attackerTimers['oldWorld|OTHER'], 2);
      final defenderTimers =
          after.worldState.spyRevealTurnsByPlayer['def'] ?? const {};
      expect(defenderTimers.containsKey(provinceId), isFalse);
      // Other player's timers unchanged.
      expect(after.worldState.spyRevealTurnsByPlayer['ally']?[provinceId], 4);
      // Visibility for attacker remains fullyVisible.
      expect(
        after.worldState.playerVisibilityByTile['att']?[tileKey],
        'fullyVisible',
      );
    });

    test('quick battle conquest in newWorld region also clears Spy timer', () {
      const nw = 'newWorld';
      const provinceId = '$nw|P1';
      const tileKey = '$nw|P1|0|0';

      final game = Game(
        id: 'g2',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: const [
              Province(id: provinceId, regionId: nw, ownerId: 'def'),
            ],
            units: [
              Unit(
                id: 'att1',
                type: 'grenadiers',
                ownerId: 'att',
                locationProvinceId: provinceId,
              ),
              Unit(
                id: 'def1',
                type: 'peasant_levies',
                ownerId: 'def',
                locationProvinceId: provinceId,
              ),
            ],
          ),
          playerVisibilityByTile: const {
            'att': {tileKey: 'fullyVisible'},
          },
          spyRevealTurnsByPlayer: const {
            'att': {provinceId: 2},
          },
          tileKeysByRegionAndProvince: const {
            nw: {
              provinceId: [tileKey],
            },
          },
        ),
        players: const [
          Player(id: 'att', displayName: 'Att', isHuman: true),
          Player(id: 'def', displayName: 'Def', isHuman: true),
        ],
      );

      const ctx = BattleContext(
        provinceId: provinceId,
        regionId: nw,
        defenderFactionId: 'def',
        defenderUnitIds: ['def1'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['att1'], generalMedals: 0),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      const result = QuickBattleResult(
        winner: QuickBattleWinner.attacker,
        attackerCasualties: ['att1'],
        defenderCasualties: ['def1'],
        provinceFlips: true,
      );

      final after = applyQuickBattleResultToGame(game, ctx, result);
      final province = after.worldState.newWorld.provinces
          .where((p) => p.id == provinceId)
          .first;
      expect(province.ownerId, 'att');
      // Spy timer map no longer contains (att, provinceId).
      expect(after.worldState.spyRevealTurnsByPlayer['att'], isNull);
      expect(
        after.worldState.playerVisibilityByTile['att']?[tileKey],
        'fullyVisible',
      );
    });
  });
}
