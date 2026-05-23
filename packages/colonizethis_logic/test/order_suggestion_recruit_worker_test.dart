/// Coverage for `suggestRecruitWorkerOrders` (Refs #2692 S7,
/// SPEC/program/order-suggestions.md § Recruit worker orders).
///
/// Each scenario asserts both the suggestion list (positive / negative
/// inclusion per `WorkerTier`) and the engine round-trip equivalence
/// guarantee: every emitted candidate must be `accepted` by
/// `OrderEngine(initialOrders: currentOrders).addRecruitWorkerOrderWithContext`,
/// matching the SPEC § Incremental candidate validation primitive contract.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _regionId = 'oldWorld';
const _provinceId = '$_regionId|P1';

final _topology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'P1',
      regionId: _regionId,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

Game _gameWith({required Player player}) => Game(
  id: 'g',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(
      provinces: [
        Province(id: _provinceId, regionId: _regionId, ownerId: player.id),
      ],
    ),
    newWorld: const RegionData(),
  ),
  players: [player],
);

PlayerView _viewFor(Game game, String playerId) =>
    buildPlayerView(game, _topology, playerId);

bool _engineAcceptsRecruit(
  Game game,
  Orders currentOrders,
  String playerId,
  RecruitWorkerOrder candidate,
) {
  final engine = OrderEngine(initialOrders: currentOrders);
  final result = engine.addRecruitWorkerOrderWithContext(
    game,
    _topology,
    playerId,
    candidate,
  );
  return result.isAccepted;
}

const _allTiers = WorkerTier.values;

void main() {
  group('suggestRecruitWorkerOrders (#2692 S7)', () {
    test(
      'returns peasant and apprentice when fabric, treasury, paper, and '
      'apprentice tech support both rows',
      () {
        // Peasant row: fabric x 2; Apprentice row: 1 peasant + 200 ducats +
        // 2 paper. Other trained tiers locked.
        final game = _gameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {
                CommodityCatalog.fabric.id: 4,
                CommodityCatalog.paper.id: 5,
              },
            ),
            workerPool: const WorkerPool(peasants: 1),
            treasury: 500,
            techUnlocked: const {
              kTechIdApprenticeWorkers: true,
              kTechIdSugarRefining: true,
            },
          ),
        );

        final list = suggestRecruitWorkerOrders(
          _viewFor(game, 'p1'),
          game,
          _topology,
          const Orders(),
        );

        expect(
          list.map((o) => o.targetTier),
          containsAllInOrder(<WorkerTier>[
            WorkerTier.peasant,
            WorkerTier.apprentice,
          ]),
        );
        expect(
          list.any((o) => o.targetTier == WorkerTier.journeyman),
          isFalse,
          reason: 'journeyman tech is locked',
        );
        expect(
          list.any((o) => o.targetTier == WorkerTier.master),
          isFalse,
          reason: 'master tech is locked',
        );

        for (final candidate in list) {
          expect(
            _engineAcceptsRecruit(game, const Orders(), 'p1', candidate),
            isTrue,
            reason:
                'engine round-trip must accept emitted candidate '
                '${candidate.targetTier.name} per SPEC equivalence guarantee',
          );
        }
      },
    );

    test(
      'omits trained tiers when their required techs are locked',
      () {
        // Affordability satisfied for all trained tiers; tech gates entirely
        // missing.
        final game = _gameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {
                CommodityCatalog.fabric.id: 10,
                CommodityCatalog.paper.id: 50,
              },
            ),
            workerPool: const WorkerPool(peasants: 5),
            treasury: 5000,
          ),
        );

        final list = suggestRecruitWorkerOrders(
          _viewFor(game, 'p1'),
          game,
          _topology,
          const Orders(),
        );

        expect(list.map((o) => o.targetTier).toList(), [WorkerTier.peasant]);

        // Engine must reject every locked-tier candidate (negative parity).
        for (final tier in _allTiers.where((t) => t != WorkerTier.peasant)) {
          final candidate = RecruitWorkerOrder(targetTier: tier);
          expect(
            _engineAcceptsRecruit(game, const Orders(), 'p1', candidate),
            isFalse,
            reason: '${tier.name} candidate rejected at the order engine '
                'because tech gate is locked',
          );
        }
      },
    );

    test(
      'omits peasant recruit when fabric is insufficient',
      () {
        final game = _gameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {CommodityCatalog.fabric.id: 1},
            ),
          ),
        );

        final list = suggestRecruitWorkerOrders(
          _viewFor(game, 'p1'),
          game,
          _topology,
          const Orders(),
        );

        expect(
          list.any((o) => o.targetTier == WorkerTier.peasant),
          isFalse,
          reason: 'peasant row needs 2 fabric',
        );
      },
    );

    test(
      'omits apprentice recruit when treasury is below 200 ducats',
      () {
        final game = _gameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {CommodityCatalog.paper.id: 5},
            ),
            workerPool: const WorkerPool(peasants: 1),
            treasury: 100,
            techUnlocked: const {
              kTechIdApprenticeWorkers: true,
              kTechIdSugarRefining: true,
            },
          ),
        );

        final list = suggestRecruitWorkerOrders(
          _viewFor(game, 'p1'),
          game,
          _topology,
          const Orders(),
        );

        expect(
          list.any((o) => o.targetTier == WorkerTier.apprentice),
          isFalse,
          reason: 'apprentice row needs 200 ducats; treasury == 100',
        );
      },
    );

    test(
      'omits apprentice recruit when peasant pool is empty',
      () {
        final game = _gameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {CommodityCatalog.paper.id: 5},
            ),
            workerPool: const WorkerPool(),
            treasury: 500,
            techUnlocked: const {
              kTechIdApprenticeWorkers: true,
              kTechIdSugarRefining: true,
            },
          ),
        );

        final list = suggestRecruitWorkerOrders(
          _viewFor(game, 'p1'),
          game,
          _topology,
          const Orders(),
        );

        expect(
          list.any((o) => o.targetTier == WorkerTier.apprentice),
          isFalse,
          reason: 'apprentice row consumes 1 peasant',
        );
      },
    );

    test(
      'returns all four tiers when all techs unlocked and resources support '
      'every cost row',
      () {
        final game = _gameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {
                CommodityCatalog.fabric.id: 4,
                CommodityCatalog.paper.id: 50,
              },
            ),
            // Three peasants -> apprentice, journeyman, master each consume one.
            workerPool: const WorkerPool(peasants: 3),
            treasury: 5000,
            techUnlocked: const {
              kTechIdApprenticeWorkers: true,
              kTechIdSugarRefining: true,
              kTechIdTrainedJourneymen: true,
              kTechIdCigarProduction: true,
              kTechIdMasterArtisans: true,
              kTechIdHatProduction: true,
            },
          ),
        );

        final list = suggestRecruitWorkerOrders(
          _viewFor(game, 'p1'),
          game,
          _topology,
          const Orders(),
        );

        // Determinism: ordering follows WorkerTier.index ascending.
        expect(
          list.map((o) => o.targetTier).toList(),
          <WorkerTier>[
            WorkerTier.peasant,
            WorkerTier.apprentice,
            WorkerTier.journeyman,
            WorkerTier.master,
          ],
        );
        for (final candidate in list) {
          expect(
            _engineAcceptsRecruit(game, const Orders(), 'p1', candidate),
            isTrue,
            reason: 'engine accepts every emitted candidate (parity)',
          );
        }
      },
    );

    test(
      'peasant reservation: pending apprentice recruit drains the only peasant '
      'so a candidate apprentice is excluded but candidate peasant remains',
      () {
        final game = _gameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {
                CommodityCatalog.fabric.id: 4,
                CommodityCatalog.paper.id: 50,
              },
            ),
            workerPool: const WorkerPool(peasants: 1),
            treasury: 5000,
            techUnlocked: const {
              kTechIdApprenticeWorkers: true,
              kTechIdSugarRefining: true,
            },
          ),
        );

        final pending = const Orders(
          recruitWorkerOrdersByPlayerId: {
            'p1': [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
          },
        );

        final list = suggestRecruitWorkerOrders(
          _viewFor(game, 'p1'),
          game,
          _topology,
          pending,
        );

        expect(
          list.any((o) => o.targetTier == WorkerTier.apprentice),
          isFalse,
          reason:
              'peasant reservation ledger: pending apprentice already '
              'consumed the only peasant',
        );
        // Peasant recruit row only needs fabric, no peasant consumed.
        expect(
          list.any((o) => o.targetTier == WorkerTier.peasant),
          isTrue,
          reason: 'peasant recruit does not consume peasants',
        );
      },
    );

    test(
      'engine round-trip parity: accept/reject decision matches '
      'addRecruitWorkerOrderWithContext for every WorkerTier in a partial '
      'tech / peasant / treasury fixture',
      () {
        // Partial: only apprentice tech; treasury below journeyman/master cost
        // rows; one peasant available; fabric for peasant.
        final game = _gameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {
                CommodityCatalog.fabric.id: 4,
                CommodityCatalog.paper.id: 50,
              },
            ),
            workerPool: const WorkerPool(peasants: 1),
            treasury: 250,
            techUnlocked: const {
              kTechIdApprenticeWorkers: true,
              kTechIdSugarRefining: true,
              kTechIdTrainedJourneymen: true,
              kTechIdCigarProduction: true,
              kTechIdMasterArtisans: true,
              kTechIdHatProduction: true,
            },
          ),
        );

        final list = suggestRecruitWorkerOrders(
          _viewFor(game, 'p1'),
          game,
          _topology,
          const Orders(),
        );

        // Suggestion includes peasant + apprentice; treasury too low for
        // journeyman (500) or master (1000).
        expect(
          list.map((o) => o.targetTier).toSet(),
          {WorkerTier.peasant, WorkerTier.apprentice},
        );

        for (final tier in _allTiers) {
          final candidate = RecruitWorkerOrder(targetTier: tier);
          final inSuggestions = list.any(
            (o) => o.targetTier == candidate.targetTier,
          );
          final engineAccepts = _engineAcceptsRecruit(
            game,
            const Orders(),
            'p1',
            candidate,
          );
          expect(
            inSuggestions,
            engineAccepts,
            reason:
                '${tier.name}: suggestion inclusion ($inSuggestions) must '
                'match engine accept ($engineAccepts) — '
                'SPEC equivalence guarantee for incremental candidate '
                'validation',
          );
        }
      },
    );

    test(
      'empty stockpile + zero treasury + zero peasants -> empty list',
      () {
        final game = _gameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
          ),
        );

        final list = suggestRecruitWorkerOrders(
          _viewFor(game, 'p1'),
          game,
          _topology,
          const Orders(),
        );
        expect(list, isEmpty);

        // Negative parity: every WorkerTier candidate is rejected by the
        // engine when the player has no resources.
        for (final tier in _allTiers) {
          expect(
            _engineAcceptsRecruit(
              game,
              const Orders(),
              'p1',
              RecruitWorkerOrder(targetTier: tier),
            ),
            isFalse,
            reason:
                '${tier.name} candidate must be engine-rejected '
                '(empty player has nothing to spend)',
          );
        }
      },
    );
  });
}
