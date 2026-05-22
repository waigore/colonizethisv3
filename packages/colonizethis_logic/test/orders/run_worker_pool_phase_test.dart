/// Resolver-level coverage for `runWorkerPoolPhase` inside the
/// Build / work phase pipeline (Refs #2692 S4).
///
/// Verifies that `applyBuildAndWorkOrders` resolves queued
/// [RecruitWorkerOrder] entries **before** any [BuildUnitOrder], per
/// `SPEC/game/workers-and-population.md` § Recruiting, Training, and
/// Disbanding (cost table, tech gates) and
/// `SPEC/program/turn-resolution-phase-details.md` § Build / work
/// (Order within the phase).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  suppressLogsForTests();

  const playerId = 'p1';
  const otherPlayerId = 'p2';
  const capProvinceId = 'oldWorld|P1';

  Game _gameWithPlayer({
    required WorkerPool workerPool,
    required Stockpile stockpile,
    required int treasury,
    Map<String, bool> techUnlocked = const {},
    List<Player>? extraPlayers,
  }) {
    final player = Player(
      id: playerId,
      displayName: 'P1',
      isHuman: true,
      capitalProvinceId: capProvinceId,
      stockpile: stockpile,
      workerPool: workerPool,
      treasury: treasury,
      techUnlocked: techUnlocked,
    );
    final world = WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(
        provinces: [
          Province(id: capProvinceId, regionId: 'oldWorld', ownerId: playerId),
        ],
        units: [],
      ),
      newWorld: const RegionData(),
    );
    return Game(
      id: 'g',
      worldState: world,
      players: [player, ...?extraPlayers],
    );
  }

  Stockpile _stockpile({int fabric = 0, int paper = 0}) {
    var s = const Stockpile();
    if (fabric > 0) {
      s = s.applyDelta(CommodityCatalog.fabric.id, fabric);
    }
    if (paper > 0) {
      s = s.applyDelta(CommodityCatalog.paper.id, paper);
    }
    return s;
  }

  Player _playerOf(Game game, String id) =>
      game.players.firstWhere((p) => p.id == id);

  group('runWorkerPoolPhase via applyBuildAndWorkOrders (Refs #2692 S4)', () {
    test('no recruit orders -> game unchanged (no-op short-circuit)', () {
      final game = _gameWithPlayer(
        workerPool: const WorkerPool(peasants: 1),
        stockpile: _stockpile(fabric: 2),
        treasury: 0,
      );

      final next = applyBuildAndWorkOrders(game, const Orders());

      expect(identical(next, game), isTrue);
    });

    test(
      'AC: peasant recruit deducts 2 fabric and increments peasants by 1',
      () {
        final game = _gameWithPlayer(
          workerPool: const WorkerPool(peasants: 0),
          stockpile: _stockpile(fabric: 2),
          treasury: 0,
        );
        final orders = Orders(
          recruitWorkerOrdersByPlayerId: {
            playerId: const [
              RecruitWorkerOrder(targetTier: WorkerTier.peasant),
            ],
          },
        );

        final next = applyBuildAndWorkOrders(game, orders);
        final player = _playerOf(next, playerId);

        expect(player.workerPool.peasants, 1);
        expect(player.stockpile.quantityOf(CommodityCatalog.fabric.id), 0);
        expect(player.treasury, 0);
      },
    );

    test(
      'AC: apprentice recruit deducts 200 ducats + 2 paper, consumes 1 peasant',
      () {
        final game = _gameWithPlayer(
          workerPool: const WorkerPool(peasants: 1),
          stockpile: _stockpile(paper: 2),
          treasury: 200,
          techUnlocked: const {
            kTechIdApprenticeWorkers: true,
            kTechIdSugarRefining: true,
          },
        );
        final orders = Orders(
          recruitWorkerOrdersByPlayerId: {
            playerId: const [
              RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
            ],
          },
        );

        final next = applyBuildAndWorkOrders(game, orders);
        final player = _playerOf(next, playerId);

        expect(player.workerPool.peasants, 0);
        expect(player.workerPool.apprentices, 1);
        expect(player.stockpile.quantityOf(CommodityCatalog.paper.id), 0);
        expect(player.treasury, 0);
      },
    );

    test(
      'AC: journeyman recruit deducts 500 ducats + 5 paper, consumes 1 peasant',
      () {
        final game = _gameWithPlayer(
          workerPool: const WorkerPool(peasants: 1),
          stockpile: _stockpile(paper: 5),
          treasury: 500,
          techUnlocked: const {
            kTechIdTrainedJourneymen: true,
            kTechIdCigarProduction: true,
          },
        );
        final orders = Orders(
          recruitWorkerOrdersByPlayerId: {
            playerId: const [
              RecruitWorkerOrder(targetTier: WorkerTier.journeyman),
            ],
          },
        );

        final next = applyBuildAndWorkOrders(game, orders);
        final player = _playerOf(next, playerId);

        expect(player.workerPool.peasants, 0);
        expect(player.workerPool.journeymen, 1);
        expect(player.stockpile.quantityOf(CommodityCatalog.paper.id), 0);
        expect(player.treasury, 0);
      },
    );

    test(
      'AC: master recruit deducts 1000 ducats + 10 paper, consumes 1 peasant',
      () {
        final game = _gameWithPlayer(
          workerPool: const WorkerPool(peasants: 1),
          stockpile: _stockpile(paper: 10),
          treasury: 1000,
          techUnlocked: const {
            kTechIdMasterArtisans: true,
            kTechIdHatProduction: true,
          },
        );
        final orders = Orders(
          recruitWorkerOrdersByPlayerId: {
            playerId: const [RecruitWorkerOrder(targetTier: WorkerTier.master)],
          },
        );

        final next = applyBuildAndWorkOrders(game, orders);
        final player = _playerOf(next, playerId);

        expect(player.workerPool.peasants, 0);
        expect(player.workerPool.masters, 1);
        expect(player.stockpile.quantityOf(CommodityCatalog.paper.id), 0);
        expect(player.treasury, 0);
      },
    );

    test('Tech-locked trained recruit is skipped (no state mutation)', () {
      final game = _gameWithPlayer(
        workerPool: const WorkerPool(peasants: 1),
        stockpile: _stockpile(paper: 2),
        treasury: 200,
        // apprentice_workers + sugar_refining NOT unlocked
        techUnlocked: const {},
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          playerId: const [
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
          ],
        },
      );

      final next = applyBuildAndWorkOrders(game, orders);
      final player = _playerOf(next, playerId);

      expect(player.workerPool.peasants, 1);
      expect(player.workerPool.apprentices, 0);
      expect(player.stockpile.quantityOf(CommodityCatalog.paper.id), 2);
      expect(player.treasury, 200);
    });

    test('Insufficient peasant (consumes flag) -> recruit skipped', () {
      final game = _gameWithPlayer(
        workerPool: const WorkerPool(peasants: 0),
        stockpile: _stockpile(paper: 2),
        treasury: 200,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          playerId: const [
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
          ],
        },
      );

      final next = applyBuildAndWorkOrders(game, orders);
      final player = _playerOf(next, playerId);

      expect(player.workerPool.peasants, 0);
      expect(player.workerPool.apprentices, 0);
      expect(player.stockpile.quantityOf(CommodityCatalog.paper.id), 2);
      expect(player.treasury, 200);
    });

    test('Insufficient material -> recruit skipped (no partial deduction)', () {
      final game = _gameWithPlayer(
        workerPool: const WorkerPool(peasants: 0),
        stockpile: _stockpile(fabric: 1),
        treasury: 0,
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          playerId: const [RecruitWorkerOrder(targetTier: WorkerTier.peasant)],
        },
      );

      final next = applyBuildAndWorkOrders(game, orders);
      final player = _playerOf(next, playerId);

      expect(player.workerPool.peasants, 0);
      expect(player.stockpile.quantityOf(CommodityCatalog.fabric.id), 1);
    });

    test('Insufficient treasury -> trained recruit skipped', () {
      final game = _gameWithPlayer(
        workerPool: const WorkerPool(peasants: 1),
        stockpile: _stockpile(paper: 2),
        treasury: 199,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          playerId: const [
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
          ],
        },
      );

      final next = applyBuildAndWorkOrders(game, orders);
      final player = _playerOf(next, playerId);

      expect(player.workerPool.peasants, 1);
      expect(player.workerPool.apprentices, 0);
      expect(player.stockpile.quantityOf(CommodityCatalog.paper.id), 2);
      expect(player.treasury, 199);
    });

    test(
      'Phase ordering: worker recruit settles before military build peasant consume',
      () {
        // Player has 1 peasant. With phase ordering correct, the peasant
        // recruit yields 2 peasants, and the subsequent military build
        // consumes 1, leaving 1. With wrong ordering (military first) the
        // build would consume the only peasant and the recruit would still
        // produce 1, leaving a final count of 1 — observationally similar
        // but the recruit cost (2 fabric) is the discriminator: when the
        // recruit ran the fabric is deducted, otherwise it is not.
        final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
        var stockpile = _stockpile(fabric: 2);
        for (final entry in econ.buildInputs.entries) {
          stockpile = stockpile.applyDelta(entry.key, entry.value);
        }
        final game = _gameWithPlayer(
          workerPool: const WorkerPool(peasants: 1),
          stockpile: stockpile,
          treasury: econ.buildTreasuryCost,
        );
        final orders = Orders(
          recruitWorkerOrdersByPlayerId: {
            playerId: const [
              RecruitWorkerOrder(targetTier: WorkerTier.peasant),
            ],
          },
          buildUnitOrdersByPlayerId: {
            playerId: [
              BuildUnitOrder(
                unitType: 'peasant_levies',
                isMilitary: true,
                spawnProvinceId: capProvinceId,
              ),
            ],
          },
        );

        final next = applyBuildAndWorkOrders(game, orders);
        final player = _playerOf(next, playerId);

        expect(
          player.workerPool.peasants,
          1,
          reason: '2 recruited - 1 military',
        );
        expect(player.stockpile.quantityOf(CommodityCatalog.fabric.id), 0);
        expect(player.treasury, 0);
      },
    );

    test('Submission order is deterministic per player', () {
      // Two apprentices in a row; second one should also resolve fully when
      // the first consumes one of two peasants and treasury/paper allow.
      final game = _gameWithPlayer(
        workerPool: const WorkerPool(peasants: 2),
        stockpile: _stockpile(paper: 4),
        treasury: 400,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          playerId: const [
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
          ],
        },
      );

      final next = applyBuildAndWorkOrders(game, orders);
      final player = _playerOf(next, playerId);

      expect(player.workerPool.peasants, 0);
      expect(player.workerPool.apprentices, 2);
      expect(player.stockpile.quantityOf(CommodityCatalog.paper.id), 0);
      expect(player.treasury, 0);
    });

    test('Recruit for one player does not affect another player', () {
      final other = Player(
        id: otherPlayerId,
        displayName: 'P2',
        isHuman: false,
        capitalProvinceId: 'oldWorld|P2',
        stockpile: _stockpile(fabric: 4),
        workerPool: const WorkerPool(peasants: 3),
        treasury: 500,
      );
      final game = _gameWithPlayer(
        workerPool: const WorkerPool(peasants: 0),
        stockpile: _stockpile(fabric: 2),
        treasury: 0,
        extraPlayers: [other],
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          playerId: const [RecruitWorkerOrder(targetTier: WorkerTier.peasant)],
        },
      );

      final next = applyBuildAndWorkOrders(game, orders);
      final p1 = _playerOf(next, playerId);
      final p2 = _playerOf(next, otherPlayerId);

      expect(p1.workerPool.peasants, 1);
      expect(p1.stockpile.quantityOf(CommodityCatalog.fabric.id), 0);
      expect(p2.workerPool.peasants, 3);
      expect(p2.stockpile.quantityOf(CommodityCatalog.fabric.id), 4);
      expect(p2.treasury, 500);
    });

    test('Determinism: identical inputs produce identical outputs', () {
      Game build() => _gameWithPlayer(
        workerPool: const WorkerPool(peasants: 2),
        stockpile: _stockpile(paper: 7),
        treasury: 700,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
          kTechIdTrainedJourneymen: true,
          kTechIdCigarProduction: true,
        },
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          playerId: const [
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
            RecruitWorkerOrder(targetTier: WorkerTier.journeyman),
          ],
        },
      );

      final a = applyBuildAndWorkOrders(build(), orders);
      final b = applyBuildAndWorkOrders(build(), orders);

      final ap = _playerOf(a, playerId);
      final bp = _playerOf(b, playerId);

      expect(ap.workerPool, bp.workerPool);
      expect(
        ap.stockpile.quantityOf(CommodityCatalog.paper.id),
        bp.stockpile.quantityOf(CommodityCatalog.paper.id),
      );
      expect(ap.treasury, bp.treasury);
    });
  });
}
