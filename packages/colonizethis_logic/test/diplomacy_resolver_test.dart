import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('tradeSlotsForGp', () {
    test('returns 0 without embassy', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
        ],
        overtureStates: const [],
      );
      expect(tradeSlotsForGp(game, 'gp1', 'minor1'), 0);
    });
    test('returns 1 with embassy', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
        ],
        overtureStates: const [
          OvertureState(gpId: 'gp1', targetId: 'minor1', stage: OvertureStage.embassy, sinceTurn: 0),
        ],
      );
      expect(tradeSlotsForGp(game, 'gp1', 'minor1'), 1);
    });
  });

  group('scoreToLevel', () {
    test('maps score ranges to levels', () {
      expect(scoreToLevel(0), RelationLevel.hostile);
      expect(scoreToLevel(25), RelationLevel.hostile);
      expect(scoreToLevel(26), RelationLevel.neutral);
      expect(scoreToLevel(50), RelationLevel.neutral);
      expect(scoreToLevel(51), RelationLevel.friendly);
      expect(scoreToLevel(75), RelationLevel.friendly);
      expect(scoreToLevel(76), RelationLevel.allied);
      expect(scoreToLevel(100), RelationLevel.allied);
    });
  });

  group('resolveDiplomacyPhase', () {
    Game _baseGame() {
      return Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 2000),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
        tribes: const [
          Tribe(id: 'tribe1', displayName: 'Tribe 1'),
        ],
      );
    }

    test('overture payments create consulate and embassy when treasury allows', () {
      final game = _baseGame();
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.establishOverture,
              targetFactionId: 'minor1',
              overtureStage: OvertureStage.tradeConsulate,
            ),
            DiplomaticOrder(
              type: DiplomaticOrderType.establishOverture,
              targetFactionId: 'minor1',
              overtureStage: OvertureStage.embassy,
            ),
          ],
        },
      );

      final after = resolveDiplomacyPhase(game, orders);
      final overture = getOverture(after, 'gp1', 'minor1');
      expect(overture, isNotNull);
      expect(overture!.hasEmbassy, isTrue);
      // Treasury reduced by consulate + embassy cost.
      final player = getPlayer(after, 'gp1')!;
      expect(player.treasury, lessThan(2000));
    });

    test('alliance order sets relation to allied', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
          Player(id: 'gp2', displayName: 'GP2', isHuman: true),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.alliance,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders);
      final rel = getRelation(after, 'gp1', 'gp2');
      expect(rel, isNotNull);
      expect(rel!.level, RelationLevel.allied);
      expect(rel.score, greaterThanOrEqualTo(76));
    });

    test('declare war and offer peace update relation state', () {
      final game = _baseGame();
      final declareOrders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'minor1',
            ),
          ],
        },
      );

      final afterWar = resolveDiplomacyPhase(game, declareOrders);
      final relWar = getRelation(afterWar, 'gp1', 'minor1')!;
      expect(relWar.atWar, isTrue);

      final peaceOrders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.offerPeace,
              targetFactionId: 'minor1',
            ),
          ],
        },
      );
      final afterPeace = resolveDiplomacyPhase(afterWar, peaceOrders);
      final relPeace = getRelation(afterPeace, 'gp1', 'minor1')!;
      expect(relPeace.atPeace, isTrue);
    });

    test('declare war when already at peace updates existing relation', () {
      var game = _baseGame().copyWith(
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 60,
            level: RelationLevel.friendly,
            state: RelationState.atPeace,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(type: DiplomaticOrderType.declareWar, targetFactionId: 'minor1'),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders);
      final rel = getRelation(after, 'gp1', 'minor1')!;
      expect(rel.atWar, isTrue);
      expect(rel.score, lessThan(60));
    });

    test('grantAid requires embassy and improves relations', () {
      var game = _baseGame().copyWith(
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );
      final initialRel = DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'minor1',
        score: 50,
        level: RelationLevel.neutral,
      );
      game = game.copyWith(diplomacyRelations: [initialRel]);

      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.grantAid,
              targetFactionId: 'minor1',
              amount: 100,
            ),
          ],
        },
      );

      final after = resolveDiplomacyPhase(game, orders);
      final rel = getRelation(after, 'gp1', 'minor1')!;
      expect(rel.score, greaterThan(initialRel.score));
      expect(tradeSlotsForGp(after, 'gp1', 'minor1'), 1);
    });

    test('join empire order advances overture when at NAP and score friendly', () {
      var game = _baseGame().copyWith(
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.nap,
            sinceTurn: 0,
          ),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 60,
            level: RelationLevel.friendly,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.establishOverture,
              targetFactionId: 'minor1',
              overtureStage: OvertureStage.joinEmpire,
            ),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders);
      final overture = getOverture(after, 'gp1', 'minor1');
      expect(overture, isNotNull);
      expect(overture!.stage, OvertureStage.joinEmpire);
    });

    test('grantAid without embassy does not change relation or treasury', () {
      final game = _baseGame().copyWith(
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 50,
            level: RelationLevel.neutral,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.grantAid,
              targetFactionId: 'minor1',
              amount: 100,
            ),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders);
      final rel = getRelation(after, 'gp1', 'minor1')!;
      expect(rel.score, 50);
      expect(getPlayer(after, 'gp1')!.treasury, 2000);
    });

    test('setSubsidy to Minor requires consulate and improves relation', () {
      var game = _baseGame().copyWith(
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.tradeConsulate,
            sinceTurn: 0,
          ),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 50,
            level: RelationLevel.neutral,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.setSubsidy,
              targetFactionId: 'minor1',
              amount: 80,
            ),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders);
      expect(getPlayer(after, 'gp1')!.treasury, 2000 - 80);
      final rel = getRelation(after, 'gp1', 'minor1')!;
      expect(rel.score, 53); // +3 per subsidy
    });

    test('setSubsidy to GP transfers treasury', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 1000),
          Player(id: 'gp2', displayName: 'GP2', isHuman: true, treasury: 500),
        ],
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'gp2',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.setSubsidy,
              targetFactionId: 'gp2',
              amount: 200,
            ),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders);
      expect(getPlayer(after, 'gp1')!.treasury, 800);
      expect(getPlayer(after, 'gp2')!.treasury, 700);
    });

    test('setSubsidy without consulate does not deduct treasury', () {
      final game = _baseGame().copyWith(
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 50,
            level: RelationLevel.neutral,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.setSubsidy,
              targetFactionId: 'minor1',
              amount: 100,
            ),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders);
      expect(getPlayer(after, 'gp1')!.treasury, 2000);
    });
  });

  group('dossier evidence (Phase 6)', () {
    test('AI declare war on weaker GP appends warmonger evidence for human observer', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI Strong', isHuman: false, militaryLevel: 3),
          Player(id: 'gp3', displayName: 'AI Weak', isHuman: false, militaryLevel: 1),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'gp3',
            score: 50,
            level: RelationLevel.neutral,
            state: RelationState.atPeace,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': const [
            DiplomaticOrder(type: DiplomaticOrderType.declareWar, targetFactionId: 'gp3'),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders);
      final evidence = after.dossierEvidenceEntries;
      expect(evidence.any((e) =>
          e.observerId == 'gp1' && e.subjectId == 'gp2' && e.agendaType == 'warmonger' && e.scoreDelta == 2),
          isTrue);
      expect(evidence.any((e) => e.description.contains('weaker neighbor')), isTrue);
    });

    test('AI declare war on ally appends backstabber evidence for human observer', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
          Player(id: 'gp3', displayName: 'Other', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'gp3',
            score: 80,
            level: RelationLevel.allied,
            state: RelationState.atPeace,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': const [
            DiplomaticOrder(type: DiplomaticOrderType.declareWar, targetFactionId: 'gp3'),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders);
      final evidence = after.dossierEvidenceEntries;
      expect(evidence.any((e) =>
          e.observerId == 'gp1' && e.subjectId == 'gp2' && e.agendaType == 'backstabber' && e.scoreDelta == 2),
          isTrue);
      expect(evidence.any((e) => e.description.contains('ally')), isTrue);
    });

    test('AI offer peace appends peacemaker evidence for human observer', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
          Player(id: 'gp3', displayName: 'Other', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'gp3',
            score: 40,
            level: RelationLevel.neutral,
            state: RelationState.atWar,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': const [
            DiplomaticOrder(type: DiplomaticOrderType.offerPeace, targetFactionId: 'gp3'),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders);
      final evidence = after.dossierEvidenceEntries;
      expect(evidence.any((e) =>
          e.observerId == 'gp1' && e.subjectId == 'gp2' && e.agendaType == 'peacemaker' && e.scoreDelta == 1),
          isTrue);
    });

    test('human declare war does not append evidence', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 50,
            level: RelationLevel.neutral,
            state: RelationState.atPeace,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(type: DiplomaticOrderType.declareWar, targetFactionId: 'gp2'),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders);
      expect(after.dossierEvidenceEntries, isEmpty);
    });
  });

  group('intervention helpers', () {
    test('needsInterventionChoice returns gp id with embassy for attacked minor', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human GP', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker GP', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'minor1',
        defenderUnitIds: const [],
        attackers: const [AttackingSide(factionId: 'gp2', unitIds: [])],
        fortLevel: 0,
        terrain: 'plains',
      );

      final gpId = needsInterventionChoice(game, ctx);
      expect(gpId, 'gp1');
    });

    test('needsInterventionChoice returns null when defender is not minor', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human GP', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker GP', isHuman: false),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'gp2',
        defenderUnitIds: const [],
        attackers: const [AttackingSide(factionId: 'gp1', unitIds: [])],
        fortLevel: 0,
        terrain: 'plains',
      );
      expect(needsInterventionChoice(game, ctx), isNull);
    });

    test('applyInterventionChoice doNothing returns game unchanged', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker', isHuman: false),
        ],
        diplomacyRelations: const [],
      );
      final ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'minor1',
        defenderUnitIds: const [],
        attackers: const [AttackingSide(factionId: 'gp2', unitIds: [])],
        fortLevel: 0,
        terrain: 'plains',
      );
      final after = applyInterventionChoice(game, ctx, 'gp1', InterventionChoice.doNothing);
      expect(after.diplomacyRelations, game.diplomacyRelations);
    });

    test('applyInterventionChoice protest reduces relation score with attacker', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 60,
            level: RelationLevel.friendly,
          ),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'minor1',
        defenderUnitIds: const [],
        attackers: const [AttackingSide(factionId: 'gp2', unitIds: [])],
        fortLevel: 0,
        terrain: 'plains',
      );
      final after = applyInterventionChoice(game, ctx, 'gp1', InterventionChoice.protest);
      final rel = getRelation(after, 'gp1', 'gp2');
      expect(rel, isNotNull);
      expect(rel!.score, lessThan(60));
    });

    test('needsInterventionChoice returns null when no GP has embassy for minor', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human GP', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker GP', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'minor1',
        defenderUnitIds: const [],
        attackers: const [AttackingSide(factionId: 'gp2', unitIds: [])],
        fortLevel: 0,
        terrain: 'plains',
      );
      final gpId = needsInterventionChoice(game, ctx);
      expect(gpId, isNull);
    });
  });
}

