import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Stockpile preview for production panel. SPEC/ui/production-panel.md,
/// SPEC/game/stockpiles-and-production.md.
void main() {
  suppressLogsForTests();

  group('previewStockpileNetDeltaByCommodityForPlayer', () {
    test('extraction only: delta matches injected extraction totals', () {
      final player = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: const Stockpile(),
      );
      final game = _singlePlayerGame(player);
      final delta = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        extractedByPlayerId: {
          'p1': {CommodityCatalog.grain.id: 4},
        },
      );
      expect(delta[CommodityCatalog.grain.id], 4);
      expect(delta.length, 1);
    });

    test('riches only: riches commodities removed, no production assignments', () {
      final player = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: const Stockpile().applyDelta(CommodityCatalog.gold.id, 2),
      );
      final game = _singlePlayerGame(player);
      final delta = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
      );
      expect(delta[CommodityCatalog.gold.id], -2);
    });

    test('consumption only: military food reduces grain', () {
      final player = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: const Stockpile().applyDelta(CommodityCatalog.grain.id, 10),
      );
      final game = Game(
        id: 't',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            units: [
              Unit(
                id: 'u1',
                type: 'peasant_levies',
                ownerId: 'p1',
                locationProvinceId: 'ow|p1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [player],
      );
      final delta = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
      );
      expect(delta[CommodityCatalog.grain.id], -1);
    });

    test('production only: net reflects recipe IO after consumption', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 50)
          .applyDelta(CommodityCatalog.meat.id, 50)
          .applyDelta(CommodityCatalog.timber.id, 20);
      const workers = WorkerPool(peasants: 10);
      final player = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: stockpile,
        workerPool: workers,
      );
      final game = _singlePlayerGame(player);
      final delta = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        defaultAssignmentsByPlayerId: {
          'p1': [
            const AssignedRecipe(
              recipeId: 'lumber_from_timber',
              assignedLabour: 10,
            ),
          ],
        },
      );
      expect(delta[CommodityCatalog.timber.id], -10);
      expect(delta[CommodityCatalog.lumber.id], 5);
      expect(delta[CommodityCatalog.grain.id] != 0, isTrue);
    });

    test('combined: extraction + riches + consumption + production', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 100)
          .applyDelta(CommodityCatalog.meat.id, 100)
          .applyDelta(CommodityCatalog.timber.id, 20)
          .applyDelta(CommodityCatalog.gems.id, 1);
      const workers = WorkerPool(peasants: 2);
      final player = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: stockpile,
        workerPool: workers,
      );
      final game = Game(
        id: 't',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            units: [
              Unit(
                id: 'u1',
                type: 'peasant_levies',
                ownerId: 'p1',
                locationProvinceId: 'ow|p1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [player],
      );
      final delta = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        extractedByPlayerId: {
          'p1': {CommodityCatalog.grain.id: 5},
        },
        defaultAssignmentsByPlayerId: {
          'p1': [
            const AssignedRecipe(
              recipeId: 'lumber_from_timber',
              assignedLabour: 4,
            ),
          ],
        },
      );
      expect(delta[CommodityCatalog.gems.id], -1);
      // Effective labour after upkeep is 2 → one lumber run (timber −2, lumber +1).
      expect(delta[CommodityCatalog.timber.id], -2);
      expect(delta[CommodityCatalog.lumber.id], 1);
      // +5 extraction, −1 regiment, −2 peasants → +2 grain vs start (100 → 102).
      expect(delta[CommodityCatalog.grain.id], 2);
    });
  });
}

Game _singlePlayerGame(Player player) {
  return Game(
    id: 't',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [player],
  );
}
