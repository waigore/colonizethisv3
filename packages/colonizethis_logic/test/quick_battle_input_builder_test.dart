import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('buildQuickBattleInput', () {
    test('produces QuickBattleInput with defender and attacker groups', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'def'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: 'att',
                provinceId: 'P1',
              ),
              Unit(
                id: 'u2',
                type: 'pikemen',
                ownerId: 'def',
                provinceId: 'P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'att', displayName: 'Attacker', isHuman: true),
          Player(id: 'def', displayName: 'Defender', isHuman: true),
        ],
      );
      const ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['u2'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['u1']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final input = buildQuickBattleInput(game, ctx);
      expect(input.provinceId, 'P1');
      expect(input.regionId, 'oldWorld');
      expect(input.attackerFactionId, 'att');
      expect(input.defenderFactionId, 'def');
      expect(input.attackerDeployment.groups.length, 1);
      expect(input.attackerDeployment.groups.first.unitIds, ['u1']);
      expect(input.defenderDeployment.groups.length, 1);
      expect(input.defenderDeployment.groups.first.unitIds, ['u2']);
      expect(input.attackerDeployment.groups.first.lane, QuickBattleLane.center);
      expect(input.attackerDeployment.groups.first.line, QuickBattleLine.front);
    });

    test('filters out unit ids not present in region', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'def'),
            ],
            units: [
              Unit(
                id: 'u2',
                type: 'pikemen',
                ownerId: 'def',
                provinceId: 'P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'att', displayName: 'Attacker', isHuman: true),
          Player(id: 'def', displayName: 'Defender', isHuman: true),
        ],
      );
      const ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['u2', 'missing'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['ghost']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final input = buildQuickBattleInput(game, ctx);
      expect(input.defenderDeployment.groups.first.unitIds, ['u2']);
      expect(input.attackerDeployment.groups.first.unitIds, isEmpty);
    });

    test('supplies leader multipliers from Game players (napoleon 1.25, frederick 1.15)', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [Province(id: 'P1', regionId: 'oldWorld', ownerId: 'def')],
            units: [
              Unit(id: 'u1', type: 'musketeers', ownerId: 'att', provinceId: 'P1'),
              Unit(id: 'u2', type: 'pikemen', ownerId: 'def', provinceId: 'P1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'att', displayName: 'France', isHuman: true, leaderKey: 'napoleon'),
          Player(id: 'def', displayName: 'Prussia', isHuman: false, leaderKey: 'frederick'),
        ],
      );
      const ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['u2'],
        attackers: [AttackingSide(factionId: 'att', unitIds: ['u1'])],
        fortLevel: 0,
        terrain: 'plains',
      );
      final input = buildQuickBattleInput(game, ctx);
      expect(input.attackerLeaderMultiplier, 1.25);
      expect(input.defenderLeaderMultiplier, 1.15);
    });

    test('leader multipliers default to 1.0 when players have no leaderKey', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [Province(id: 'P1', regionId: 'oldWorld', ownerId: 'def')],
            units: [
              Unit(id: 'u1', type: 'musketeers', ownerId: 'att', provinceId: 'P1'),
              Unit(id: 'u2', type: 'pikemen', ownerId: 'def', provinceId: 'P1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'att', displayName: 'Attacker', isHuman: true),
          Player(id: 'def', displayName: 'Defender', isHuman: true),
        ],
      );
      const ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['u2'],
        attackers: [AttackingSide(factionId: 'att', unitIds: ['u1'])],
        fortLevel: 0,
        terrain: 'plains',
      );
      final input = buildQuickBattleInput(game, ctx);
      expect(input.attackerLeaderMultiplier, 1.0);
      expect(input.defenderLeaderMultiplier, 1.0);
    });
  });
}
