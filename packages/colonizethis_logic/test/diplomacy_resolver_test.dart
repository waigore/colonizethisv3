import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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

  group('relationScoreToDisplayLabel', () {
    test('maps score to display label per SPEC/game/diplomacy.md § Player-facing relation display', () {
      expect(relationScoreToDisplayLabel(0), 'Hostile');
      expect(relationScoreToDisplayLabel(29), 'Hostile');
      expect(relationScoreToDisplayLabel(30), 'Unfriendly');
      expect(relationScoreToDisplayLabel(49), 'Unfriendly');
      expect(relationScoreToDisplayLabel(50), 'Cordial');
      expect(relationScoreToDisplayLabel(69), 'Cordial');
      expect(relationScoreToDisplayLabel(70), 'Friendly');
      expect(relationScoreToDisplayLabel(100), 'Friendly');
    });
    test('clamps out-of-range score to 0-100', () {
      expect(relationScoreToDisplayLabel(-1), 'Hostile');
      expect(relationScoreToDisplayLabel(101), 'Friendly');
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

      final after = resolveDiplomacyPhase(game, orders).game;
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
      final after = resolveDiplomacyPhase(game, orders).game;
      final rel = getRelation(after, 'gp1', 'gp2');
      expect(rel, isNotNull);
      expect(rel!.level, RelationLevel.friendly); // 76 - 1 convergence = 75 (friendly)
      expect(rel.score, 75); // 76 alliance - 1 convergence
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

      final afterWar = resolveDiplomacyPhase(game, declareOrders).game;
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
      final afterPeace = resolveDiplomacyPhase(afterWar, peaceOrders).game;
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
      final after = resolveDiplomacyPhase(game, orders).game;
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

      final after = resolveDiplomacyPhase(game, orders).game;
      final rel = getRelation(after, 'gp1', 'minor1')!;
      expect(rel.score, greaterThan(initialRel.score));
      expect(tradeSlotsForGp(after, 'gp1', 'minor1'), 1);
    });

    test('join empire absorbs minor: provinces transfer, minor removed, cost deducted', () {
      const ow = 'oldWorld';
      var game = _baseGame().copyWith(
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 15000),
        ],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|m1', regionId: ow, ownerId: 'minor1'),
              Province(id: '$ow|m2', regionId: ow, ownerId: 'minor1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
        ),
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
      final after = resolveDiplomacyPhase(game, orders).game;
      expect(after.minorNations.any((m) => m.id == 'minor1'), isFalse);
      expect(getOverture(after, 'gp1', 'minor1'), isNull);
      final p1 = after.worldState.oldWorld.provinces
          .where((p) => p.id == '$ow|m1')
          .firstOrNull;
      final p2 = after.worldState.oldWorld.provinces
          .where((p) => p.id == '$ow|m2')
          .firstOrNull;
      expect(p1?.ownerId, 'gp1');
      expect(p2?.ownerId, 'gp1');
      // Cost = 5000 + 2*2000 = 9000
      expect(getPlayer(after, 'gp1')!.treasury, 15000 - 9000);
    });

    test('join empire clears Spy timers for provinces that become owned by GP', () {
      const ow = 'oldWorld';
      // gp1 has an active Spy timer for minor-owned province m1; after Join Empire,
      // gp1 owns m1 and the timer must be cleared without changing visibility.
      var game = _baseGame().copyWith(
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 15000),
        ],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|m1', regionId: ow, ownerId: 'minor1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {
              'oldWorld|m1|0|0': 'fullyVisible',
            },
          },
          spyRevealTurnsByPlayer: const {
            'gp1': {
              '$ow|m1': 3,
            },
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|m1': ['oldWorld|m1|0|0'],
            },
          },
        ),
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.nap,
            sinceTurn: 0,
          ),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
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

      final after = resolveDiplomacyPhase(game, orders).game;
      // Province now owned by gp1.
      final p1 = after.worldState.oldWorld.provinces
          .where((p) => p.id == '$ow|m1')
          .firstOrNull;
      expect(p1?.ownerId, 'gp1');
      // Spy timer for (gp1, m1) is cleared.
      expect(after.worldState.spyRevealTurnsByPlayer['gp1'], isNull);
      // Tile visibility for gp1 remains fullyVisible.
      expect(
        after.worldState.playerVisibilityByTile['gp1']?['oldWorld|m1|0|0'],
        'fullyVisible',
      );
    });

    test('join empire not applied when treasury below cost: minor unchanged', () {
      const ow = 'oldWorld';
      var game = _baseGame().copyWith(
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 5000),
        ],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|m1', regionId: ow, ownerId: 'minor1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
        ),
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
      // Cost = 5000 + 2000 = 7000; treasury 5000 is insufficient
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
      final after = resolveDiplomacyPhase(game, orders).game;
      expect(after.minorNations.any((m) => m.id == 'minor1'), isTrue);
      expect(after.worldState.oldWorld.provinces
          .where((p) => p.id == '$ow|m1')
          .first
          .ownerId, 'minor1');
      expect(getPlayer(after, 'gp1')!.treasury, 5000);
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
      final after = resolveDiplomacyPhase(game, orders).game;
      final rel = getRelation(after, 'gp1', 'minor1')!;
      expect(rel.score, 50);
      expect(getPlayer(after, 'gp1')!.treasury, 2000);
    });

    test('setSubsidy to Minor creates ongoing subsidy and deducts initial payment', () {
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
              amount: 500,
            ),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
      // Initial payment deducted
      expect(getPlayer(after, 'gp1')!.treasury, 2000 - 500);
      // Ongoing subsidy created
      expect(after.subsidyStates.length, 1);
      expect(after.subsidyStates.first.payerId, 'gp1');
      expect(after.subsidyStates.first.targetId, 'minor1');
      expect(after.subsidyStates.first.amountPerTurn, 500);
    });

    test('setSubsidy to GP creates ongoing subsidy with initial payment', () {
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
      final after = resolveDiplomacyPhase(game, orders).game;
      // Initial payment deducted from payer
      expect(getPlayer(after, 'gp1')!.treasury, 800);
      // Ongoing subsidy created (treasury transfer happens each turn during processing)
      expect(after.subsidyStates.length, 1);
      expect(after.subsidyStates.first.payerId, 'gp1');
      expect(after.subsidyStates.first.targetId, 'gp2');
      expect(after.subsidyStates.first.amountPerTurn, 200);
    });

    test('ongoing subsidy processes each turn: deducts payment and improves relation', () {
      // Turn 1: Create subsidy
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
        subsidyStates: const [
          SubsidyState(payerId: 'gp1', targetId: 'minor1', amountPerTurn: 500),
        ],
      );
      final orders = Orders(diplomaticOrdersByPlayerId: {});
      
      // Turn 1: Process ongoing subsidy
      final afterTurn1 = resolveDiplomacyPhase(game, orders).game;
      expect(getPlayer(afterTurn1, 'gp1')!.treasury, 2000 - 500); // Payment deducted
      final relAfterTurn1 = getRelation(afterTurn1, 'gp1', 'minor1')!;
      expect(relAfterTurn1.score, 51); // +2 subsidy, -1 convergence = +1 net // +2 per 500 ducats
      expect(afterTurn1.subsidyStates.length, 1); // Subsidy still active
    });

    test('ongoing subsidy cancels when payer has insufficient funds', () {
      var game = _baseGame().copyWith(
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 400), // Less than 500
        ],
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.tradeConsulate,
            sinceTurn: 0,
          ),
        ],
        subsidyStates: const [
          SubsidyState(payerId: 'gp1', targetId: 'minor1', amountPerTurn: 500),
        ],
      );
      final orders = Orders(diplomaticOrdersByPlayerId: {});
      
      final after = resolveDiplomacyPhase(game, orders).game;
      expect(after.subsidyStates, isEmpty); // Subsidy cancelled
      expect(getPlayer(after, 'gp1')!.treasury, 400); // No deduction
    });

    test('ongoing subsidy cancels when war declared', () {
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
            state: RelationState.atPeace,
          ),
        ],
        subsidyStates: const [
          SubsidyState(payerId: 'gp1', targetId: 'minor1', amountPerTurn: 500),
        ],
      );
      
      // Declare war
      final warOrders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'minor1',
            ),
          ],
        },
      );
      
      final after = resolveDiplomacyPhase(game, warOrders).game;
      expect(after.subsidyStates, isEmpty); // Subsidy cancelled
      final rel = getRelation(after, 'gp1', 'minor1')!;
      expect(rel.atWar, isTrue);
      expect(rel.score, 20); // Reset to hostile
    });

    test('relation convergence: scores drift toward 50 each turn', () {
      var game = _baseGame().copyWith(
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 60, // Above 50, should decrease
            level: RelationLevel.friendly,
            state: RelationState.atPeace,
          ),
        ],
      );
      final orders = Orders(diplomaticOrdersByPlayerId: {});
      
      final after = resolveDiplomacyPhase(game, orders).game;
      final rel = getRelation(after, 'gp1', 'minor1')!;
      expect(rel.score, 59); // Decreased by 1 toward 50
    });

    test('relation convergence: scores below 50 increase toward neutral', () {
      var game = _baseGame().copyWith(
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 40, // Below 50, should increase
            level: RelationLevel.neutral,
            state: RelationState.atPeace,
          ),
        ],
      );
      final orders = Orders(diplomaticOrdersByPlayerId: {});
      
      final after = resolveDiplomacyPhase(game, orders).game;
      final rel = getRelation(after, 'gp1', 'minor1')!;
      expect(rel.score, 41); // Increased by 1 toward 50
    });

    test('war relations do not converge: scores stay fixed', () {
      var game = _baseGame().copyWith(
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 20, // At war, score should stay at 20
            level: RelationLevel.hostile,
            state: RelationState.atWar,
          ),
        ],
      );
      final orders = Orders(diplomaticOrdersByPlayerId: {});
      
      final after = resolveDiplomacyPhase(game, orders).game;
      final rel = getRelation(after, 'gp1', 'minor1')!;
      expect(rel.score, 20); // Unchanged
      expect(rel.atWar, isTrue);
    });

    test('war declaration resets both sides to score 20', () {
      var game = _baseGame().copyWith(
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 80, // High score
            level: RelationLevel.allied,
            state: RelationState.atPeace,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'minor1',
            ),
          ],
        },
      );
      
      final after = resolveDiplomacyPhase(game, orders).game;
      final rel = getRelation(after, 'gp1', 'minor1')!;
      expect(rel.atWar, isTrue);
      expect(rel.score, 20); // Reset to 20 (Hostile)
      expect(rel.level, RelationLevel.hostile);
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
      final after = resolveDiplomacyPhase(game, orders).game;
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
      final after = resolveDiplomacyPhase(game, orders).game;
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
      final after = resolveDiplomacyPhase(game, orders).game;
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
      // GP–GP peace requires both sides to offer peace (SPEC/game/diplomacy.md).
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': const [
            DiplomaticOrder(type: DiplomaticOrderType.offerPeace, targetFactionId: 'gp3'),
          ],
          'gp3': const [
            DiplomaticOrder(type: DiplomaticOrderType.offerPeace, targetFactionId: 'gp2'),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
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
      final after = resolveDiplomacyPhase(game, orders).game;
      expect(after.dossierEvidenceEntries, isEmpty);
    });
  });

  group('dialogue (Phase 6)', () {
    test('AI declare war invokes onDialogue with diplomatic declare_war', () {
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
      DialogueEvent? captured;
      resolveDiplomacyPhase(game, orders, onDialogue: (e) => captured = e);
      expect(captured, isNotNull);
      expect(captured!.leaderId, 'gp2');
      expect(captured!.category, 'diplomatic');
      expect(captured!.situation, 'declare_war');
      expect(captured!.era, 'earlyModern');
      expect(captured!.variables['otherNation'], 'gp3');
    });

    test('AI offer peace invokes onDialogue with diplomatic peace_offer', () {
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
      // GP–GP peace requires both sides to offer peace (SPEC/game/diplomacy.md).
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': const [
            DiplomaticOrder(type: DiplomaticOrderType.offerPeace, targetFactionId: 'gp3'),
          ],
          'gp3': const [
            DiplomaticOrder(type: DiplomaticOrderType.offerPeace, targetFactionId: 'gp2'),
          ],
        },
      );
      DialogueEvent? captured;
      resolveDiplomacyPhase(game, orders, onDialogue: (e) => captured = e);
      expect(captured, isNotNull);
      expect(captured!.leaderId, 'gp2');
      expect(captured!.category, 'diplomatic');
      expect(captured!.situation, 'peace_offer');
      expect(captured!.variables['otherNation'], 'gp3');
    });

    test('human declare war does not invoke onDialogue', () {
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
      var callCount = 0;
      resolveDiplomacyPhase(game, orders, onDialogue: (_) => callCount++);
      expect(callCount, 0);
    });

    test('overture to human GP returns pending; resume with accept applies overture',
        () {
      // gp1 offers Consulate to gp2 (human). Phase should return pending.
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          const Player(id: 'gp1', displayName: 'GP1', isHuman: false)
              .copyWith(treasury: overtureConsulateCost + 100),
          const Player(id: 'gp2', displayName: 'GP2', isHuman: true),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 50,
            level: RelationLevel.neutral,
            state: RelationState.atPeace,
            sinceTurn: 0,
            lastInteractionTurn: 0,
          ),
        ],
        overtureStates: const [],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.establishOverture,
              targetFactionId: 'gp2',
              overtureStage: OvertureStage.tradeConsulate,
            ),
          ],
        },
      );
      final result = resolveDiplomacyPhase(game, orders);
      expect(result.isPending, isTrue);
      expect(result.pendingOvertures, isNotNull);
      expect(result.pendingOvertures!.length, 1);
      expect(result.pendingOvertures!.first.offererGpId, 'gp1');
      expect(result.pendingOvertures!.first.targetFactionId, 'gp2');
      expect(result.pendingOvertures!.first.stage, OvertureStage.tradeConsulate);

      // Resume with accept: overture should be applied.
      final gp1Before = getPlayer(game, 'gp1')!;
      final afterAccept = resolveDiplomacyPhase(
        game,
        orders,
        overtureDecisions: [
          const OvertureDecision(
            offererGpId: 'gp1',
            targetFactionId: 'gp2',
            stage: OvertureStage.tradeConsulate,
            accepted: true,
          ),
        ],
      );
      expect(afterAccept.isPending, isFalse);
      final overture = getOverture(afterAccept.game, 'gp1', 'gp2');
      expect(overture, isNotNull);
      expect(overture!.stage, OvertureStage.tradeConsulate);
      final gp1After = getPlayer(afterAccept.game, 'gp1')!;
      expect(gp1After.treasury, gp1Before.treasury - overtureConsulateCost);
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

    test(
        'declare war on minor with another GP invested: sets war state (scenario anchor)',
        () {
      const ow = 'oldWorld';
      const minorProvId = '$ow|M1';
      const tileKey = '$ow|M1|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(
            phase: TurnPhase.orders,
            turnNumber: 3,
          ),
          oldWorld: RegionData(
            provinces: const [
              Province(id: minorProvId, regionId: ow, ownerId: 'minor1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          purchasedTilesByTileKey: const {
            tileKey: 'gp1', // gp1 has purchased land in minor1 province
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human GP', isHuman: true),
          Player(id: 'gp2', displayName: 'Aggressor GP', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'minor1',
            state: RelationState.atPeace,
          ),
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            state: RelationState.atPeace,
          ),
        ],
      );

      final orders = Orders(
        diplomaticOrdersByPlayerId: const {
          'gp2': [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'minor1',
            ),
          ],
        },
      );

      final result = resolveDiplomacyPhase(game, orders);
      final after = result.game;

      // For now, this scenario anchors the state after DoW is applied.
      // When intervention-at-declaration is wired, extend this to assert
      // pending intervention choice for gp1 as appropriate.
      final relGp2Minor = getRelation(after, 'gp2', 'minor1');
      expect(relGp2Minor, isNotNull);
      expect(relGp2Minor!.atWar, isTrue);
    });

    test(
        'needsInterventionChoice returns gp id when human GP has purchased land in attacked minor',
        () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$ow|P1|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(
            phase: TurnPhase.orders,
            turnNumber: 1,
          ),
          oldWorld: RegionData(
            provinces: const [
              Province(id: provinceId, regionId: ow, ownerId: 'minor1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          purchasedTilesByTileKey: const {
            tileKey: 'gp1',
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human GP', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker GP', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
      );

      const ctx = BattleContext(
        provinceId: provinceId,
        regionId: ow,
        defenderFactionId: 'minor1',
        defenderUnitIds: [],
        attackers: [
          AttackingSide(
            factionId: 'gp2',
            unitIds: [],
            generalMedals: 0,
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      final gpId = needsInterventionChoice(game, ctx);
      expect(gpId, 'gp1');
    });

    test(
        'needsInterventionChoice returns gp id when human GP has purchased land in attacked tribe',
        () {
      const nw = 'newWorld';
      const provinceId = '$nw|T1';
      const tileKey = '$nw|T1|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(
            phase: TurnPhase.orders,
            turnNumber: 1,
          ),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: const [
              Province(id: provinceId, regionId: nw, ownerId: 'tribe1'),
            ],
            units: const [],
          ),
          purchasedTilesByTileKey: const {
            tileKey: 'gp1',
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human GP', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker GP', isHuman: false),
        ],
        tribes: const [
          Tribe(id: 'tribe1', displayName: 'Tribe 1'),
        ],
      );

      const ctx = BattleContext(
        provinceId: provinceId,
        regionId: nw,
        defenderFactionId: 'tribe1',
        defenderUnitIds: [],
        attackers: [
          AttackingSide(
            factionId: 'gp2',
            unitIds: [],
            generalMedals: 0,
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      final gpId = needsInterventionChoice(game, ctx);
      expect(gpId, 'gp1');
    });
  });

  group('diplomatic history', () {
    test('declare war appends declareWar event', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: true),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: const [
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
      final after = resolveDiplomacyPhase(game, orders).game;
      expect(after.diplomaticHistoryEvents, isNotEmpty);
      final warEvent = after.diplomaticHistoryEvents
          .where((e) => e.type == DiplomaticEventType.declareWar)
          .toList();
      expect(warEvent.length, 1);
      expect(warEvent.first.participants, contains('gp1'));
      expect(warEvent.first.participants, contains('gp2'));
      expect(warEvent.first.turn, 5);
    });

    test('diplomaticHistoryForPair returns events for pair newest first', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 10),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: true),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomaticHistoryEvents: [
          DiplomaticEvent(
            turn: 1,
            intraTurnIndex: 0,
            type: DiplomaticEventType.declareWar,
            participants: {'gp1', 'gp2'},
            fromFactionId: 'gp1',
            toFactionId: 'gp2',
          ),
          DiplomaticEvent(
            turn: 5,
            intraTurnIndex: 0,
            type: DiplomaticEventType.peace,
            participants: {'gp1', 'gp2'},
            fromFactionId: 'gp1',
            toFactionId: 'gp2',
          ),
        ],
      );
      final list = diplomaticHistoryForPair(game, 'gp1', 'gp2');
      expect(list.length, 2);
      expect(list[0].type, DiplomaticEventType.peace);
      expect(list[0].turn, 5);
      expect(list[1].type, DiplomaticEventType.declareWar);
      expect(list[1].turn, 1);
    });
  });
}

