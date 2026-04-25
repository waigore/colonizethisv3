import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('resolveDiplomacyPhase', () {
    Game baseGame() {
      return Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          const Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 2000)
              .copyWith(techUnlocked: const {'diplomatic_expertise': true}),
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
      final game = baseGame();
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
      final player = after.playerById('gp1')!;
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
      final game = baseGame();
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
      var game = baseGame().copyWith(
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
      var game = baseGame().copyWith(
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
              amount: 1000,
            ),
          ],
        },
      );

      final after = resolveDiplomacyPhase(game, orders).game;
      final rel = getRelation(after, 'gp1', 'minor1')!;
      expect(rel.score, greaterThan(initialRel.score));
      expect(tradeSlotsForGp(after, 'gp1', 'minor1'), 3);
      expect(after.playerById('gp1')!.treasury, 2000 - 1000);
    });

    test('grantAid at resolution with wrong multiple throws StateError', () {
      var game = baseGame().copyWith(
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );
      game = game.copyWith(
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
              amount: 500,
            ),
          ],
        },
      );
      expect(
        () => resolveDiplomacyPhase(game, orders),
        throwsStateError,
      );
    });

    test('setSubsidy at resolution with wrong multiple throws StateError', () {
      var game = baseGame().copyWith(
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.tradeConsulate,
            sinceTurn: 0,
          ),
        ],
      );
      game = game.copyWith(
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
              amount: 150,
            ),
          ],
        },
      );
      expect(
        () => resolveDiplomacyPhase(game, orders),
        throwsStateError,
      );
    });

    test('join empire absorbs minor: provinces transfer, minor removed, cost deducted', () {
      const ow = 'oldWorld';
      var game = baseGame().copyWith(
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
            units: [],
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
      expect(after.playerById('gp1')!.treasury, 15000 - 9000);
    });

    test('join empire clears Spy timers for provinces that become owned by GP', () {
      const ow = 'oldWorld';
      // gp1 has an active Spy timer for minor-owned province m1; after Join Empire,
      // gp1 owns m1 and the timer must be cleared without changing visibility.
      var game = baseGame().copyWith(
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 15000),
        ],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|m1', regionId: ow, ownerId: 'minor1'),
            ],
            units: [],
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

    test(
      'join empire relocates illegal civilian in changed province to owner capital',
      () {
        const ow = 'oldWorld';
        const absorbedProvince = '$ow|m1';
        const absorbedTile = '$ow|m1|0|0';
        const foreignCapProvince = '$ow|c1';
        const foreignCapTile = '$ow|c1|0|0';

        var game = baseGame().copyWith(
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 15000),
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              capitalProvinceId: foreignCapProvince,
              capitalTile: CapitalTile(regionId: ow, provinceId: 'c1', x: 0, y: 0),
            ),
          ],
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: absorbedProvince, regionId: ow, ownerId: 'minor1'),
                Province(id: foreignCapProvince, regionId: ow, ownerId: 'gp2'),
              ],
              units: [
                Unit(
                  id: 'foreign_builder',
                  type: 'Builder',
                  ownerId: 'gp2',
                  locationProvinceId: absorbedProvince,
                  tileKey: absorbedTile,
                ),
              ],
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
          diplomacyRelations: const [
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
        final relocated = after.worldState.oldWorld.units
            .where((u) => u.id == 'foreign_builder')
            .single;
        expect(relocated.tileKey, foreignCapTile);
        expect(relocated.locationProvinceId, foreignCapProvince);
        expect(relocated.status, UnitStatus.idle);
        expect(relocated.currentWork, isNull);
        expect(relocated.originTileKey, isNull);
        expect(relocated.assignedTileKey, isNull);
      },
    );

    test(
      'join empire relocates idle foreign civilian with stale assignment '
      'tracking but no currentWork to owner capital',
      () {
        const ow = 'oldWorld';
        const absorbedProvince = '$ow|m1';
        const absorbedTile = '$ow|m1|0|0';
        const foreignCapProvince = '$ow|c1';
        const foreignCapTile = '$ow|c1|0|0';

        var game = baseGame().copyWith(
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 15000),
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              capitalProvinceId: foreignCapProvince,
              capitalTile: CapitalTile(regionId: ow, provinceId: 'c1', x: 0, y: 0),
            ),
          ],
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: absorbedProvince, regionId: ow, ownerId: 'minor1'),
                Province(id: foreignCapProvince, regionId: ow, ownerId: 'gp2'),
              ],
              units: [
                Unit(
                  id: 'foreign_builder',
                  type: 'Builder',
                  ownerId: 'gp2',
                  locationProvinceId: absorbedProvince,
                  tileKey: absorbedTile,
                  status: UnitStatus.idle,
                  originTileKey: absorbedTile,
                  assignedTileKey: absorbedTile,
                ),
              ],
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
          diplomacyRelations: const [
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
        final relocated = after.worldState.oldWorld.units
            .where((u) => u.id == 'foreign_builder')
            .single;
        expect(relocated.tileKey, foreignCapTile);
        expect(relocated.locationProvinceId, foreignCapProvince);
        expect(relocated.status, UnitStatus.idle);
        expect(relocated.currentWork, isNull);
        expect(relocated.originTileKey, isNull);
        expect(relocated.assignedTileKey, isNull);
      },
    );

    test('join empire not applied when treasury below cost: minor unchanged', () {
      const ow = 'oldWorld';
      var game = baseGame().copyWith(
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 5000),
        ],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|m1', regionId: ow, ownerId: 'minor1'),
            ],
            units: [],
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
      expect(after.playerById('gp1')!.treasury, 5000);
    });

    test('grantAid without embassy does not change relation or treasury', () {
      final game = baseGame().copyWith(
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
              amount: 1000,
            ),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
      final rel = getRelation(after, 'gp1', 'minor1')!;
      expect(rel.score, 50);
      expect(after.playerById('gp1')!.treasury, 2000);
    });

    test('setSubsidy to Minor creates ongoing subsidy and deducts initial payment', () {
      var game = baseGame().copyWith(
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
      expect(after.playerById('gp1')!.treasury, 2000 - 500);
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
      expect(after.playerById('gp1')!.treasury, 800);
      // Ongoing subsidy created (treasury transfer happens each turn during processing)
      expect(after.subsidyStates.length, 1);
      expect(after.subsidyStates.first.payerId, 'gp1');
      expect(after.subsidyStates.first.targetId, 'gp2');
      expect(after.subsidyStates.first.amountPerTurn, 200);
    });

    test('ongoing subsidy processes each turn: deducts payment and improves relation', () {
      // Turn 1: Create subsidy
      var game = baseGame().copyWith(
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
      expect(afterTurn1.playerById('gp1')!.treasury, 2000 - 500); // Payment deducted
      final relAfterTurn1 = getRelation(afterTurn1, 'gp1', 'minor1')!;
      expect(relAfterTurn1.score, 51); // +2 subsidy, -1 convergence = +1 net // +2 per 500 ducats
      expect(afterTurn1.subsidyStates.length, 1); // Subsidy still active
    });

    test('ongoing subsidy cancels when payer has insufficient funds', () {
      var game = baseGame().copyWith(
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
      expect(after.playerById('gp1')!.treasury, 400); // No deduction
    });

    test('ongoing subsidy cancels when war declared', () {
      var game = baseGame().copyWith(
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
      var game = baseGame().copyWith(
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
      var game = baseGame().copyWith(
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
      var game = baseGame().copyWith(
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
      var game = baseGame().copyWith(
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
      final game = baseGame().copyWith(
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
      expect(after.playerById('gp1')!.treasury, 2000);
    });

    test('game treasury unchanged before diplomacy phase; grant applies on resolve', () {
      var game = baseGame().copyWith(
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
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
              type: DiplomaticOrderType.grantAid,
              targetFactionId: 'minor1',
              amount: 1000,
            ),
          ],
        },
      );
      expect(game.playerById('gp1')!.treasury, 2000);
      final after = resolveDiplomacyPhase(game, orders).game;
      expect(after.playerById('gp1')!.treasury, 1000);
    });

    test(
      'grantAid at resolution throws StateError when amount is not a multiple of £1000',
      () {
        var game = baseGame().copyWith(
          overtureStates: const [
            OvertureState(
              gpId: 'gp1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
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
                type: DiplomaticOrderType.grantAid,
                targetFactionId: 'minor1',
                amount: 1500,
              ),
            ],
          },
        );
        expect(
          () => resolveDiplomacyPhase(game, orders),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('GrantAid'),
            ),
          ),
        );
      },
    );

    test(
      'setSubsidy at resolution throws StateError when amount is not a multiple of £100',
      () {
        var game = baseGame().copyWith(
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
                amount: 150,
              ),
            ],
          },
        );
        expect(
          () => resolveDiplomacyPhase(game, orders),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('SetSubsidy'),
            ),
          ),
        );
      },
    );

    test('join empire absorbs nearly defeated Great Power', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|BC', regionId: ow, ownerId: 'gp_a'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'gp_b'),
              Province(id: '$ow|P3', regionId: ow, ownerId: 'gp_b'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'gp_a',
            displayName: 'A',
            isHuman: true,
            treasury: 20000,
            techUnlocked: const {'empire_building': true},
          ),
          const Player(
            id: 'gp_b',
            displayName: 'B',
            isHuman: false,
            capitalProvinceId: '$ow|BC',
          ),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp_a',
            factionId2: 'gp_b',
            score: 60,
            level: RelationLevel.friendly,
          ),
        ],
        overtureStates: const [
          OvertureState(
            gpId: 'gp_a',
            targetId: 'gp_b',
            stage: OvertureStage.nap,
            sinceTurn: 0,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp_a': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.establishOverture,
              targetFactionId: 'gp_b',
              overtureStage: OvertureStage.joinEmpire,
            ),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
      expect(after.players.any((p) => p.id == 'gp_b'), isFalse);
      expect(after.playerById('gp_a')!.treasury, 20000 - 9000);
      expect(
        after.worldState.oldWorld.provinces
            .where((p) => p.id == '$ow|P2' || p.id == '$ow|P3')
            .every((p) => p.ownerId == 'gp_a'),
        isTrue,
      );
    });
  });
}
