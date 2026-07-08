// Table-driven economy extraction scenarios (Refs #3939 phase 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'core_economy_test_support.dart';
import 'scenario_runner.dart';

/// One row in [applyExtractionToStockpileScenarios].
class ApplyExtractionToStockpileScenario implements RefsScenario {
  const ApplyExtractionToStockpileScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runApplyExtractionToStockpileScenario(
  ApplyExtractionToStockpileScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for [applyExtractionToStockpile].
List<ApplyExtractionToStockpileScenario> applyExtractionToStockpileScenarios() =>
    [
      ApplyExtractionToStockpileScenario(
        label: 'adds extracted quantities to stockpile',
        run: () {
          const stockpile = Stockpile();
          final extracted = {
            CommodityCatalog.grain.id: 5,
            CommodityCatalog.iron.id: 2,
          };

          final updated = applyExtractionToStockpile(stockpile, extracted);

          expect(updated.quantityOf(CommodityCatalog.grain.id), 5);
          expect(updated.quantityOf(CommodityCatalog.iron.id), 2);
        },
      ),
      ApplyExtractionToStockpileScenario(
        label: 'accumulates on existing stockpile',
        run: () {
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
        },
      ),
      ApplyExtractionToStockpileScenario(
        label: 'ignores negative values in extracted',
        run: () {
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
        },
      ),
      ApplyExtractionToStockpileScenario(
        label: 'zero quantities do not change stockpile',
        run: () {
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
        },
      ),
      ApplyExtractionToStockpileScenario(
        label: 'empty extracted returns same stockpile',
        run: () {
          var stockpile = const Stockpile().applyDelta(
            CommodityCatalog.grain.id,
            5,
          );

          final updated = applyExtractionToStockpile(stockpile, const {});

          expect(updated.quantityOf(CommodityCatalog.grain.id), 5);
        },
      ),
      ApplyExtractionToStockpileScenario(
        label:
            'adds large extraction without storage cap (unbounded strategic stockpile)',
        run: () {
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
      ),
    ];

/// One row in [applyExtractionForPlayersScenarios].
class ApplyExtractionForPlayersScenario implements RefsScenario {
  const ApplyExtractionForPlayersScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runApplyExtractionForPlayersScenario(
  ApplyExtractionForPlayersScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for [applyExtractionForPlayers].
List<ApplyExtractionForPlayersScenario> applyExtractionForPlayersScenarios() =>
    [
      ApplyExtractionForPlayersScenario(
        label: 'applies per-player extraction to player stockpiles',
        run: () {
          final game = minimalTwoPlayerGame();
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
        },
      ),
      ApplyExtractionForPlayersScenario(
        label: 'players with no extraction keep existing stockpile',
        run: () {
          var p1 = const Player(
            id: 'p1',
            displayName: 'A',
            isHuman: true,
          ).copyWith(
            stockpile: const Stockpile().applyDelta(CommodityCatalog.grain.id, 7),
          );
          final game = minimalTwoPlayerGame(
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
        },
      ),
      ApplyExtractionForPlayersScenario(
        label: 'empty extractedByPlayerId returns game unchanged',
        run: () {
          final game = minimalTwoPlayerGame(
            players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
          );

          final updated = applyExtractionForPlayers(game, {});

          expect(updated.players, game.players);
        },
      ),
    ];
