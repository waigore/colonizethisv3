import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Tests for economy_extraction.dart. SPEC/program/auto-transport.md.
void main() {
  group('applyExtractionToStockpile', () {
    test('adds extracted quantities to stockpile', () {
      const stockpile = Stockpile();
      final extracted = {
        CommodityCatalog.grain.id: 5,
        CommodityCatalog.iron.id: 2,
      };

      final updated = applyExtractionToStockpile(stockpile, extracted);

      expect(updated.quantityOf(CommodityCatalog.grain.id), 5);
      expect(updated.quantityOf(CommodityCatalog.iron.id), 2);
    });

    test('accumulates on existing stockpile', () {
      var stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 3)
          .applyDelta(CommodityCatalog.meat.id, 1);
      final extracted = {
        CommodityCatalog.grain.id: 4,
        CommodityCatalog.meat.id: 2,
      };

      final updated = applyExtractionToStockpile(stockpile, extracted);

      expect(updated.quantityOf(CommodityCatalog.grain.id), 7);
      expect(updated.quantityOf(CommodityCatalog.meat.id), 3);
    });

    test('ignores negative values in extracted', () {
      var stockpile = const Stockpile().applyDelta(
        CommodityCatalog.grain.id,
        10,
      );
      final extracted = {
        CommodityCatalog.grain.id: -2,
        CommodityCatalog.meat.id: 3,
      };

      final updated = applyExtractionToStockpile(stockpile, extracted);

      expect(updated.quantityOf(CommodityCatalog.grain.id), 10);
      expect(updated.quantityOf(CommodityCatalog.meat.id), 3);
    });

    test('zero quantities do not change stockpile', () {
      var stockpile = const Stockpile().applyDelta(
        CommodityCatalog.grain.id,
        5,
      );
      final extracted = {
        CommodityCatalog.grain.id: 0,
        CommodityCatalog.iron.id: 0,
      };

      final updated = applyExtractionToStockpile(stockpile, extracted);

      expect(updated.quantityOf(CommodityCatalog.grain.id), 5);
    });

    test('empty extracted returns same stockpile', () {
      var stockpile = const Stockpile().applyDelta(
        CommodityCatalog.grain.id,
        5,
      );

      final updated = applyExtractionToStockpile(stockpile, const {});

      expect(updated.quantityOf(CommodityCatalog.grain.id), 5);
    });

    test(
      'adds large extraction without storage cap (unbounded strategic stockpile)',
      () {
        const existing = 1000000;
        const incoming = 500000;
        var stockpile = const Stockpile().applyDelta(
          CommodityCatalog.grain.id,
          existing,
        );
        final extracted = {CommodityCatalog.grain.id: incoming};

        final updated = applyExtractionToStockpile(stockpile, extracted);

        expect(
          updated.quantityOf(CommodityCatalog.grain.id),
          existing + incoming,
        );
      },
    );
  });

  group('applyExtractionForPlayers', () {
    test('applies per-player extraction to player stockpiles', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
          Player(id: 'p2', displayName: 'B', isHuman: false),
        ],
      );
      final extractedByPlayerId = {
        'p1': {CommodityCatalog.grain.id: 3, CommodityCatalog.iron.id: 1},
        'p2': {CommodityCatalog.iron.id: 2, CommodityCatalog.coal.id: 4},
      };

      final updated = applyExtractionForPlayers(game, extractedByPlayerId);

      expect(
        updated.players[0].stockpile.quantityOf(CommodityCatalog.grain.id),
        3,
      );
      expect(
        updated.players[0].stockpile.quantityOf(CommodityCatalog.iron.id),
        1,
      );
      expect(
        updated.players[1].stockpile.quantityOf(CommodityCatalog.iron.id),
        2,
      );
      expect(
        updated.players[1].stockpile.quantityOf(CommodityCatalog.coal.id),
        4,
      );
    });

    test('players with no extraction keep existing stockpile', () {
      var p1 = const Player(id: 'p1', displayName: 'A', isHuman: true).copyWith(
        stockpile: const Stockpile().applyDelta(CommodityCatalog.grain.id, 7),
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          p1,
          const Player(id: 'p2', displayName: 'B', isHuman: false),
        ],
      );
      final extractedByPlayerId = {
        'p2': {CommodityCatalog.iron.id: 2},
      };

      final updated = applyExtractionForPlayers(game, extractedByPlayerId);

      expect(
        updated.players[0].stockpile.quantityOf(CommodityCatalog.grain.id),
        7,
      );
      expect(
        updated.players[1].stockpile.quantityOf(CommodityCatalog.iron.id),
        2,
      );
    });

    test('empty extractedByPlayerId returns game unchanged', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
      );

      final updated = applyExtractionForPlayers(game, {});

      expect(updated.players, game.players);
    });
  });
}
