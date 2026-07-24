import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app_debug/colonizethis_app_debug.dart';
import 'package:colonizethis_app_debug/colonizethis_app_debug.dart';
import 'package:colonizethis_app_debug/colonizethis_app_debug.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Game emptyWorldGame({
    required String id,
    TurnPhase phase = TurnPhase.orders,
    int turnNumber = 1,
    required List<Player> players,
  }) {
    return Game(
      id: id,
      worldState: WorldState(
        turnState: TurnState(phase: phase, turnNumber: turnNumber),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: players,
    );
  }

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
      final game = emptyWorldGame(
        id: 'g-treasury',
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
      final game = emptyWorldGame(
        id: 'g-treasury2',
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
      final game = emptyWorldGame(
        id: 'g-treasury3',
        phase: TurnPhase.movement,
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
      final game = emptyWorldGame(
        id: 'g-stockpile',
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
      final game = emptyWorldGame(
        id: 'g-stockpile2',
        phase: TurnPhase.movement,
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
      final game = emptyWorldGame(
        id: 'g-stockpile3',
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
    const flipHuman = Player(
      id: 'human_1',
      displayName: 'Human',
      isHuman: true,
    );
    const flipAi = Player(id: 'ai_1', displayName: 'AI', isHuman: false);

    Game baseGame({
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
        players: const [flipHuman, flipAi],
      );
    }

    FlipDebugProvinceOwnershipEvent nameEvent([
      String displayName = 'New Bordeaux',
    ]) {
      return FlipDebugProvinceOwnershipEvent(
        humanPlayerId: 'human_1',
        regionId: 'oldWorld',
        provinceDisplayName: displayName,
      );
    }

    ({Game? game, String message}) flip(
      Game game,
      FlipDebugProvinceOwnershipEvent event,
    ) {
      return applyDebugFlipProvinceOwnership(
        currentGame: game,
        event: event,
        combinedTopology: const MapTopology(),
      );
    }

    test('flips province through canonical transfer on valid command', () {
      final result = flip(
        baseGame(
          phase: TurnPhase.orders,
          ownerId: 'ai_1',
          humanVisibility: 'fogged',
        ),
        nameEvent(),
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
      final result = flip(
        baseGame(
          phase: TurnPhase.movement,
          ownerId: 'ai_1',
          humanVisibility: 'fogged',
        ),
        nameEvent(),
      );

      expect(result.game, isNull);
      expect(
        result.message,
        contains('allowed only during human Orders phase'),
      );
    });

    test('rejects unknown province visibility to human', () {
      final result = flip(
        baseGame(
          phase: TurnPhase.orders,
          ownerId: 'ai_1',
          humanVisibility: 'unknown',
        ),
        nameEvent(),
      );

      expect(result.game, isNull);
      expect(result.message, contains('unknown to human player'));
    });

    test('rejects already human-owned province', () {
      final result = flip(
        baseGame(
          phase: TurnPhase.orders,
          ownerId: 'human_1',
          humanVisibility: 'fogged',
        ),
        nameEvent(),
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
        players: const [flipHuman, flipAi],
      );

      final result = flip(game, nameEvent());

      expect(result.game, isNull);
      expect(result.message, contains('ambiguous'));
    });

    test('rejects province display name not found in region', () {
      final result = flip(
        baseGame(
          phase: TurnPhase.orders,
          ownerId: 'ai_1',
          humanVisibility: 'fogged',
        ),
        nameEvent('Nonexistent Province'),
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
        players: const [flipHuman, flipAi],
      );

      final result = flip(game, nameEvent());

      expect(result.game, isNull);
      expect(result.message, contains('no current owner'));
    });

    test('JSON round-trip preserves flip outcome (persistence parity)', () {
      final result = flip(
        baseGame(
          phase: TurnPhase.orders,
          ownerId: 'ai_1',
          humanVisibility: 'fogged',
        ),
        nameEvent(),
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
          players: const [flipHuman, flipAi],
        );
        final result = flip(game, nameEvent());
        expect(result.game, isNull);
        expect(
          result.message,
          contains('Candidates: oldWorld|P1, oldWorld|P2'),
        );
        expect(result.message, contains('/flip_province <regionId|localId>'));
      },
    );

    test('flip resolves directly by full province id', () {
      final result = flip(
        baseGame(
          phase: TurnPhase.orders,
          ownerId: 'ai_1',
          humanVisibility: 'fogged',
        ),
        const FlipDebugProvinceOwnershipEvent(
          humanPlayerId: 'human_1',
          fullProvinceId: 'oldWorld|P1',
        ),
      );
      expect(result.game, isNotNull);
      expect(
        result.game!.worldState.oldWorld.provinces.single.ownerId,
        'human_1',
      );
    });
  });
}
