import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/core/services/app_event_handler_debug_flip_province.dart';
import 'package:colonizethis_app/core/services/app_event_handler_debug_spawn_civilian.dart';
import 'package:colonizethis_app/core/services/app_event_handler_debug_spawn_regiment.dart';
import 'package:colonizethis_app/core/services/app_event_handler_debug_stockpile.dart';
import 'package:colonizethis_app/core/services/app_event_handler_debug_treasury.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Game gameWithMode(CombatMode mode) {
    return Game(
      id: 'g1',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: const [
        Player(id: 'p1', displayName: 'P1', isHuman: true),
        Player(id: 'p2', displayName: 'P2', isHuman: false),
      ],
      defaultCombatMode: mode,
    );
  }

  group('applyCombatModeChoiceToGame', () {
    test('returns null when there is no active game', () {
      final updated = applyCombatModeChoiceToGame(null, CombatMode.quickBattle);
      expect(updated, isNull);
    });

    test('returns same instance when mode is unchanged', () {
      final game = gameWithMode(CombatMode.quickBattle);
      final updated = applyCombatModeChoiceToGame(game, CombatMode.quickBattle);
      expect(identical(updated, game), isTrue);
    });

    test('updates default combat mode when player picks a new mode', () {
      final game = gameWithMode(CombatMode.autoResolve);
      final updated = applyCombatModeChoiceToGame(game, CombatMode.quickBattle);
      expect(updated, isNotNull);
      expect(updated!.defaultCombatMode, CombatMode.quickBattle);
      expect(updated.id, game.id);
    });
  });

  group('applyDebugCivilianSpawnAtCapital', () {
    test('returns message when there is no active game', () {
      const event = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'p1',
        unitType: kUnitTypeExplorer,
      );
      final result = applyDebugCivilianSpawnAtCapital(
        currentGame: null,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, contains('no active game'));
    });

    test('spawns requested civilian count at human capital tile', () {
      final game = Game(
        id: 'g2',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'oldWorld|1',
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|1',
              x: 2,
              y: 3,
            ),
          ),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );
      const event = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'p1',
        unitType: kUnitTypeBuilder,
        count: 2,
      );
      final result = applyDebugCivilianSpawnAtCapital(
        currentGame: game,
        event: event,
      );

      expect(result.game, isNotNull);
      expect(result.message, contains('Spawned 2 Builder'));
      final units = result.game!.worldState.oldWorld.units;
      expect(units, hasLength(2));
      expect(units.every((u) => u.type == kUnitTypeBuilder), isTrue);
      expect(units.every((u) => u.tileKey == 'oldWorld|1|2|3'), isTrue);
      expect(units.map((u) => u.id).toSet().length, 2);
    });

    test('rejects unsupported unit type', () {
      final game = Game(
        id: 'g3',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'oldWorld|1',
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|1',
              x: 2,
              y: 3,
            ),
          ),
        ],
      );
      const event = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'p1',
        unitType: 'InvalidType',
      );
      final result = applyDebugCivilianSpawnAtCapital(
        currentGame: game,
        event: event,
      );

      expect(result.game, isNull);
      expect(result.message, contains('unsupported civilian type'));
    });

    test('continues deterministic canonical unit id sequence', () {
      final game = Game(
        id: 'g4',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'unit_7',
                type: kUnitTypeBuilder,
                ownerId: 'p1',
                locationProvinceId: 'oldWorld|1',
                tileKey: 'oldWorld|1|2|3',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'oldWorld|1',
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|1',
              x: 2,
              y: 3,
            ),
          ),
        ],
      );
      const event = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'p1',
        unitType: kUnitTypeBuilder,
        count: 2,
      );
      final result = applyDebugCivilianSpawnAtCapital(
        currentGame: game,
        event: event,
      );

      final ids = result.game!.worldState.oldWorld.units
          .map((u) => u.id)
          .toList();
      expect(ids, contains('unit_8'));
      expect(ids, contains('unit_9'));
    });

    test('caps oversized debug spawn count to 25', () {
      final game = Game(
        id: 'g5',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'oldWorld|1',
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|1',
              x: 2,
              y: 3,
            ),
          ),
        ],
      );
      const event = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'p1',
        unitType: kUnitTypeExplorer,
        count: 99,
      );
      final result = applyDebugCivilianSpawnAtCapital(
        currentGame: game,
        event: event,
      );

      expect(result.game, isNotNull);
      expect(result.game!.worldState.oldWorld.units, hasLength(25));
      expect(result.message, contains('Spawned 25 Explorer'));
    });

    test('rejects zero or negative count', () {
      final game = Game(
        id: 'g6',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'oldWorld|1',
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|1',
              x: 2,
              y: 3,
            ),
          ),
        ],
      );
      const event = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'p1',
        unitType: kUnitTypeExplorer,
        count: 0,
      );
      final result = applyDebugCivilianSpawnAtCapital(
        currentGame: game,
        event: event,
      );

      expect(result.game, isNull);
      expect(result.message, contains('count must be >= 1'));
    });
  });

  group('applyDebugRegimentSpawnAtCapital', () {
    test('returns message when there is no active game', () {
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'p1',
        regimentTypeId: 'peasant_levies',
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: null,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, contains('no active game'));
    });

    test('spawns regiment into region units and home army', () {
      final game = Game(
        id: 'g-reg-1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'oldWorld|1',
          ),
        ],
      );
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'p1',
        regimentTypeId: 'peasant_levies',
        count: 2,
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      final next = result.game;
      expect(next, isNotNull);
      final units = next!.worldState.oldWorld.units;
      expect(units, hasLength(2));
      expect(units.every((u) => u.type == 'peasant_levies'), isTrue);
      expect(units.every((u) => u.tileKey == null), isTrue);
      expect(units.every((u) => u.status == UnitStatus.idle), isTrue);
      expect(units.every((u) => u.medals == 0), isTrue);
      expect(units.every((u) => u.currentWork == null), isTrue);
      final homeArmy = next.worldState.armies.singleWhere(
        (a) => a.id == 'army_p1',
      );
      expect(homeArmy.regimentUnitIds, hasLength(2));
      expect(units.every((u) => u.id.startsWith('unit_')), isTrue);
    });

    test('fails on unknown player and keeps state unchanged', () {
      final game = Game(
        id: 'g-reg-2',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'unknown',
        regimentTypeId: 'peasant_levies',
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, contains('unknown player'));
    });

    test('fails on missing capital and keeps state unchanged', () {
      final game = Game(
        id: 'g-reg-3',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'p1',
        regimentTypeId: 'peasant_levies',
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, contains('no capital province'));
    });

    test('fails when matched player is not human', () {
      final game = Game(
        id: 'g-reg-not-human',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(
            id: 'p2',
            displayName: 'P2',
            isHuman: false,
            capitalProvinceId: 'oldWorld|1',
          ),
        ],
      );
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'p2',
        regimentTypeId: 'peasant_levies',
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, contains('is not human'));
    });

    test(
      'fails on malformed capital province id and keeps state unchanged',
      () {
        final game = Game(
          id: 'g-reg-invalid-capital',
          worldState: const WorldState(
            turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(),
            newWorld: RegionData(),
          ),
          players: const [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: 'malformed',
            ),
          ],
        );
        const event = SpawnDebugRegimentAtCapitalEvent(
          humanPlayerId: 'p1',
          regimentTypeId: 'peasant_levies',
        );
        final result = applyDebugRegimentSpawnAtCapital(
          currentGame: game,
          event: event,
        );
        expect(result.game, isNull);
        expect(result.message, contains('invalid capital province id'));
      },
    );

    test('fails on unsupported regiment type and keeps state unchanged', () {
      final game = Game(
        id: 'g-reg-4',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'oldWorld|1',
          ),
        ],
      );
      const event = SpawnDebugRegimentAtCapitalEvent(
        humanPlayerId: 'p1',
        regimentTypeId: 'unknown',
      );
      final result = applyDebugRegimentSpawnAtCapital(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, contains('unsupported regiment type'));
    });
  });

  group('applyDebugTreasuryCredit', () {
    test('returns message when there is no active game', () {
      const event = CreditDebugTreasuryEvent(
        humanPlayerId: 'p1',
        requestedAmount: 10,
        creditedAmount: 10,
      );
      final result = applyDebugTreasuryCredit(currentGame: null, event: event);
      expect(result.game, isNull);
      expect(result.message, contains('no active game'));
    });

    test('adds credited amount to human player treasury', () {
      final game = Game(
        id: 'g-treasury',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true, treasury: 100),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );
      const event = CreditDebugTreasuryEvent(
        humanPlayerId: 'p1',
        requestedAmount: 50,
        creditedAmount: 50,
      );
      final result = applyDebugTreasuryCredit(currentGame: game, event: event);
      expect(result.game, isNotNull);
      final p1 = result.game!.players.firstWhere((p) => p.id == 'p1');
      expect(p1.treasury, 150);
      expect(result.message, contains('+50'));
      expect(result.message, contains('150'));
    });

    test('clamped success message includes requested and credited amounts', () {
      final game = Game(
        id: 'g-treasury2',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true, treasury: 0),
        ],
      );
      const event = CreditDebugTreasuryEvent(
        humanPlayerId: 'p1',
        requestedAmount: 12000,
        creditedAmount: 9999,
      );
      final result = applyDebugTreasuryCredit(currentGame: game, event: event);
      expect(result.game!.players.single.treasury, 9999);
      expect(result.message, contains('12000'));
      expect(result.message, contains('9999'));
    });

    test('rejects command outside human orders phase', () {
      final game = Game(
        id: 'g-treasury3',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.movement, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true, treasury: 10),
        ],
      );
      const event = CreditDebugTreasuryEvent(
        humanPlayerId: 'p1',
        requestedAmount: 50,
        creditedAmount: 50,
      );
      final result = applyDebugTreasuryCredit(currentGame: game, event: event);
      expect(result.game, isNull);
      expect(
        result.message,
        contains('allowed only during human Orders phase'),
      );
    });
  });

  group('applyDebugStockpileCredit', () {
    test('adds credited amount to human player stockpile commodity', () {
      final game = Game(
        id: 'g-stockpile',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            stockpile: Stockpile(quantities: {'grain': 100}),
          ),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );
      const event = CreditDebugStockpileCommodityEvent(
        humanPlayerId: 'p1',
        commodityId: 'grain',
        requestedAmount: 50,
        creditedAmount: 50,
      );
      final result = applyDebugStockpileCredit(currentGame: game, event: event);
      expect(result.game, isNotNull);
      final p1 = result.game!.players.firstWhere((p) => p.id == 'p1');
      expect(p1.stockpile.quantityOf('grain'), 150);
      expect(result.message, contains('grain'));
      expect(result.message, contains('150'));
    });

    test('rejects add_resource command outside human orders phase', () {
      final game = Game(
        id: 'g-stockpile2',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.movement, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      const event = CreditDebugStockpileCommodityEvent(
        humanPlayerId: 'p1',
        commodityId: 'grain',
        requestedAmount: 50,
        creditedAmount: 50,
      );
      final result = applyDebugStockpileCredit(currentGame: game, event: event);
      expect(result.game, isNull);
      expect(
        result.message,
        contains('allowed only during human Orders phase'),
      );
    });

    test('clamped success message includes requested and credited amounts', () {
      final game = Game(
        id: 'g-stockpile3',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      const event = CreditDebugStockpileCommodityEvent(
        humanPlayerId: 'p1',
        commodityId: 'castIron',
        requestedAmount: 12000,
        creditedAmount: 9999,
      );
      final result = applyDebugStockpileCredit(currentGame: game, event: event);
      expect(result.game, isNotNull);
      expect(
        result.game!.players.single.stockpile.quantityOf('castIron'),
        9999,
      );
      expect(result.message, contains('12000'));
      expect(result.message, contains('9999'));
    });
  });

  group('applyDebugFlipProvinceOwnership', () {
    Game _baseGame({
      required TurnPhase phase,
      required String ownerId,
      required String humanVisibility,
    }) {
      return Game(
        id: 'g-flip',
        worldState: WorldState(
          turnState: TurnState(phase: phase, turnNumber: 2),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|P1',
                regionId: 'oldWorld',
                ownerId: ownerId,
                displayName: 'New Bordeaux',
              ),
            ],
            units: [
              Unit(
                id: 'r1',
                type: 'musketeers',
                ownerId: ownerId,
                locationProvinceId: 'oldWorld|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              'oldWorld|P1': ['oldWorld|P1|0|0'],
            },
          },
          playerVisibilityByTile: {
            'human_1': {'oldWorld|P1|0|0': humanVisibility},
          },
        ),
        players: const [
          Player(id: 'human_1', displayName: 'Human', isHuman: true),
          Player(id: 'ai_1', displayName: 'AI', isHuman: false),
        ],
      );
    }

    test('flips province through canonical transfer on valid command', () {
      final game = _baseGame(
        phase: TurnPhase.orders,
        ownerId: 'ai_1',
        humanVisibility: 'fogged',
      );
      const event = FlipDebugProvinceOwnershipEvent(
        humanPlayerId: 'human_1',
        regionId: 'oldWorld',
        provinceDisplayName: 'New Bordeaux',
      );

      final result = applyDebugFlipProvinceOwnership(
        currentGame: game,
        event: event,
        combinedTopology: const MapTopology(),
      );

      expect(result.game, isNotNull);
      expect(
        result.game!.worldState.oldWorld.provinces.single.ownerId,
        'human_1',
      );
      expect(result.game!.worldState.oldWorld.units.single.ownerId, 'human_1');
      expect(result.message, contains('Flipped province oldWorld|P1'));
      expect(result.message, contains('Regiments transferred: 1'));
    });

    test('rejects command outside human orders phase', () {
      final game = _baseGame(
        phase: TurnPhase.movement,
        ownerId: 'ai_1',
        humanVisibility: 'fogged',
      );
      const event = FlipDebugProvinceOwnershipEvent(
        humanPlayerId: 'human_1',
        regionId: 'oldWorld',
        provinceDisplayName: 'New Bordeaux',
      );

      final result = applyDebugFlipProvinceOwnership(
        currentGame: game,
        event: event,
        combinedTopology: const MapTopology(),
      );

      expect(result.game, isNull);
      expect(
        result.message,
        contains('allowed only during human Orders phase'),
      );
    });

    test('rejects unknown province visibility to human', () {
      final game = _baseGame(
        phase: TurnPhase.orders,
        ownerId: 'ai_1',
        humanVisibility: 'unknown',
      );
      const event = FlipDebugProvinceOwnershipEvent(
        humanPlayerId: 'human_1',
        regionId: 'oldWorld',
        provinceDisplayName: 'New Bordeaux',
      );

      final result = applyDebugFlipProvinceOwnership(
        currentGame: game,
        event: event,
        combinedTopology: const MapTopology(),
      );

      expect(result.game, isNull);
      expect(result.message, contains('unknown to human player'));
    });

    test('rejects already human-owned province', () {
      final game = _baseGame(
        phase: TurnPhase.orders,
        ownerId: 'human_1',
        humanVisibility: 'fogged',
      );
      const event = FlipDebugProvinceOwnershipEvent(
        humanPlayerId: 'human_1',
        regionId: 'oldWorld',
        provinceDisplayName: 'New Bordeaux',
      );

      final result = applyDebugFlipProvinceOwnership(
        currentGame: game,
        event: event,
        combinedTopology: const MapTopology(),
      );

      expect(result.game, isNull);
      expect(result.message, contains('already human-owned'));
    });

    test('rejects ambiguous province display name in region', () {
      final game = Game(
        id: 'g-flip-amb',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|P1',
                regionId: 'oldWorld',
                ownerId: 'ai_1',
                displayName: 'New Bordeaux',
              ),
              Province(
                id: 'oldWorld|P2',
                regionId: 'oldWorld',
                ownerId: 'ai_1',
                displayName: 'new bordeaux',
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              'P1': ['oldWorld|P1|0|0'],
              'P2': ['oldWorld|P2|0|0'],
            },
          },
          playerVisibilityByTile: {
            'human_1': {
              'oldWorld|P1|0|0': 'fogged',
              'oldWorld|P2|0|0': 'fogged',
            },
          },
        ),
        players: const [
          Player(id: 'human_1', displayName: 'Human', isHuman: true),
          Player(id: 'ai_1', displayName: 'AI', isHuman: false),
        ],
      );
      const event = FlipDebugProvinceOwnershipEvent(
        humanPlayerId: 'human_1',
        regionId: 'oldWorld',
        provinceDisplayName: 'New Bordeaux',
      );

      final result = applyDebugFlipProvinceOwnership(
        currentGame: game,
        event: event,
        combinedTopology: const MapTopology(),
      );

      expect(result.game, isNull);
      expect(result.message, contains('ambiguous'));
    });

    test('rejects province display name not found in region', () {
      final game = _baseGame(
        phase: TurnPhase.orders,
        ownerId: 'ai_1',
        humanVisibility: 'fogged',
      );
      const event = FlipDebugProvinceOwnershipEvent(
        humanPlayerId: 'human_1',
        regionId: 'oldWorld',
        provinceDisplayName: 'Nonexistent Province',
      );

      final result = applyDebugFlipProvinceOwnership(
        currentGame: game,
        event: event,
        combinedTopology: const MapTopology(),
      );

      expect(result.game, isNull);
      expect(result.message, contains('not found'));
    });

    test('rejects province with no current owner', () {
      final game = Game(
        id: 'g-flip-null-owner',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: const RegionData(
            provinces: [
              Province(
                id: 'oldWorld|P1',
                regionId: 'oldWorld',
                ownerId: null,
                displayName: 'New Bordeaux',
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              'P1': ['oldWorld|P1|0|0'],
            },
          },
          playerVisibilityByTile: {
            'human_1': {'oldWorld|P1|0|0': 'fogged'},
          },
        ),
        players: const [
          Player(id: 'human_1', displayName: 'Human', isHuman: true),
          Player(id: 'ai_1', displayName: 'AI', isHuman: false),
        ],
      );
      const event = FlipDebugProvinceOwnershipEvent(
        humanPlayerId: 'human_1',
        regionId: 'oldWorld',
        provinceDisplayName: 'New Bordeaux',
      );

      final result = applyDebugFlipProvinceOwnership(
        currentGame: game,
        event: event,
        combinedTopology: const MapTopology(),
      );

      expect(result.game, isNull);
      expect(result.message, contains('no current owner'));
    });

    test('JSON round-trip preserves flip outcome (persistence parity)', () {
      final game = _baseGame(
        phase: TurnPhase.orders,
        ownerId: 'ai_1',
        humanVisibility: 'fogged',
      );
      const event = FlipDebugProvinceOwnershipEvent(
        humanPlayerId: 'human_1',
        regionId: 'oldWorld',
        provinceDisplayName: 'New Bordeaux',
      );

      final result = applyDebugFlipProvinceOwnership(
        currentGame: game,
        event: event,
        combinedTopology: const MapTopology(),
      );

      expect(result.game, isNotNull);
      final restored = Game.fromJson(result.game!.toJson());
      expect(restored.worldState.oldWorld.provinces.single.ownerId, 'human_1');
      expect(restored.worldState.oldWorld.units.single.ownerId, 'human_1');
    });

    test(
      'flip ambiguity error includes candidate ids and id retry guidance',
      () {
        final game = Game(
          id: 'g-flip-amb-ids',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|P2',
                  regionId: 'oldWorld',
                  ownerId: 'ai_1',
                  displayName: 'New Bordeaux',
                ),
                Province(
                  id: 'oldWorld|P1',
                  regionId: 'oldWorld',
                  ownerId: 'ai_1',
                  displayName: 'New Bordeaux',
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: const {
              'oldWorld': {
                'oldWorld|P1': ['oldWorld|P1|0|0'],
                'oldWorld|P2': ['oldWorld|P2|0|0'],
              },
            },
            playerVisibilityByTile: {
              'human_1': {
                'oldWorld|P1|0|0': 'fogged',
                'oldWorld|P2|0|0': 'fogged',
              },
            },
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
            Player(id: 'ai_1', displayName: 'AI', isHuman: false),
          ],
        );
        const event = FlipDebugProvinceOwnershipEvent(
          humanPlayerId: 'human_1',
          regionId: 'oldWorld',
          provinceDisplayName: 'New Bordeaux',
        );
        final result = applyDebugFlipProvinceOwnership(
          currentGame: game,
          event: event,
          combinedTopology: const MapTopology(),
        );
        expect(result.game, isNull);
        expect(
          result.message,
          contains('Candidates: oldWorld|P1, oldWorld|P2'),
        );
        expect(result.message, contains('/flip_province <regionId|localId>'));
      },
    );

    test('flip resolves directly by full province id', () {
      final game = _baseGame(
        phase: TurnPhase.orders,
        ownerId: 'ai_1',
        humanVisibility: 'fogged',
      );
      const event = FlipDebugProvinceOwnershipEvent(
        humanPlayerId: 'human_1',
        fullProvinceId: 'oldWorld|P1',
      );
      final result = applyDebugFlipProvinceOwnership(
        currentGame: game,
        event: event,
        combinedTopology: const MapTopology(),
      );
      expect(result.game, isNotNull);
      expect(
        result.game!.worldState.oldWorld.provinces.single.ownerId,
        'human_1',
      );
    });

  });
}
