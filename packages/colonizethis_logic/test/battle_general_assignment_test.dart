import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/combat/leader_bonus_helpers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('assignGeneralsForBattleContext + CombatPhaseGeneralLedger', () {
    test(
        'second attack in same phase excludes general already used as attacker',
        () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 4),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'p1', regionId: 'oldWorld', ownerId: 'def'),
              Province(id: 'p2', regionId: 'oldWorld', ownerId: 'def'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'att', displayName: 'Att', isHuman: true),
          Player(id: 'def', displayName: 'Def', isHuman: true),
        ],
        generals: const [
          General(id: 'g1', ownerId: 'att', medals: 2),
        ],
      );
      final ledger = CombatPhaseGeneralLedger();
      const ctx1 = BattleContext(
        provinceId: 'p1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [AttackingSide(factionId: 'att', unitIds: ['a1'])],
        fortLevel: 0,
        terrain: 'plains',
      );
      final a1 = assignGeneralsForBattleContext(
        game: game,
        ctx: ctx1,
        rng: battleAssignmentRng(game, ctx1),
        ledger: ledger,
      );
      expect(a1.attackerByFactionId['att']!.generalId, 'g1');
      recordAttackCommandersForResolvedBattle(ctx1, a1, ledger);

      const ctx2 = BattleContext(
        provinceId: 'p2',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d2'],
        attackers: [AttackingSide(factionId: 'att', unitIds: ['a2'])],
        fortLevel: 0,
        terrain: 'plains',
      );
      final a2 = assignGeneralsForBattleContext(
        game: game,
        ctx: ctx2,
        rng: battleAssignmentRng(game, ctx2),
        ledger: ledger,
      );
      expect(a2.attackerByFactionId['att']!.generalId, isNull);
      expect(
        a2.attackerByFactionId['att']!.medals,
        fallbackGeneralMedalsFromLeader(game, 'att'),
      );
    });

    test('defender pool not filtered by attack ledger for same faction', () {
      final ledger = CombatPhaseGeneralLedger()
        ..attackCommanderGeneralIdsByFaction['att'] = {'g1'};
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'px', regionId: 'oldWorld', ownerId: 'att'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'att', displayName: 'Att', isHuman: true),
          Player(id: 'def', displayName: 'Def', isHuman: true),
        ],
        generals: const [
          General(id: 'g1', ownerId: 'att', medals: 1),
        ],
      );
      const ctx = BattleContext(
        provinceId: 'px',
        regionId: 'oldWorld',
        defenderFactionId: 'att',
        defenderUnitIds: ['x1'],
        attackers: [AttackingSide(factionId: 'def', unitIds: ['e1'])],
        fortLevel: 0,
        terrain: 'plains',
      );
      final a = assignGeneralsForBattleContext(
        game: game,
        ctx: ctx,
        rng: battleAssignmentRng(game, ctx),
        ledger: ledger,
      );
      expect(a.defenderGeneralId, 'g1');
      expect(a.defenderMedals, 1);
    });

    test('battleAssignmentRng matches for auto and QB same context', () {
      final game = Game(
        id: 'g1',
        globalGameSeed: 99,
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 7),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
      );
      const ctx = BattleContext(
        provinceId: 'oldWorld|P9',
        regionId: 'oldWorld',
        defenderFactionId: 'd',
        defenderUnitIds: [],
        attackers: [
          AttackingSide(factionId: 'a', unitIds: ['u1']),
        ],
        fortLevel: 0,
        terrain: 'hills',
      );
      final r1 = battleAssignmentRng(game, ctx);
      final r2 = battleAssignmentRng(game, ctx);
      expect(r1.nextInt(1 << 30), r2.nextInt(1 << 30));
    });
  });
}
