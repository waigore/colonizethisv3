// Compact recruit-worker suggestion assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_recruit_worker_fixtures.dart';
import 'order_suggestion_recruit_worker_test_support.dart';

/// Pins for [orderSuggestionRecruitWorkerInclusionScenarios] and
/// [orderSuggestionRecruitWorkerParityScenarios] rows.
enum OrderSuggestionRecruitWorkerTarget {
  returnsPeasantAndApprenticeWhenSupported,
  omitsTrainedTiersWhenTechsLocked,
  omitsPeasantWhenFabricInsufficient,
  omitsApprenticeWhenTreasuryBelow200,
  omitsApprenticeWhenPeasantPoolEmpty,
  returnsAllFourTiersWhenFullyUnlocked,
  peasantReservationExcludesApprenticeCandidate,
  engineRoundTripParityPartialFixture,
  emptyPlayerReturnsEmptyList,
}

void runOrderSuggestionRecruitWorkerExpectation(
  OrderSuggestionRecruitWorkerTarget target,
) {
  switch (target) {
    case OrderSuggestionRecruitWorkerTarget.returnsPeasantAndApprenticeWhenSupported:
      final game = recruitWorkerInclusionPeasantAndApprenticeGame();
      final list = suggestRecruitWorkerOrders(
        recruitWorkerTestViewFor(game, 'p1'),
        game,
        recruitWorkerTestTopology,
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
          recruitWorkerTestEngineAccepts(
            game,
            const Orders(),
            'p1',
            candidate,
          ),
          isTrue,
          reason:
              'engine round-trip must accept emitted candidate '
              '${candidate.targetTier.name} per SPEC equivalence guarantee',
        );
      }

    case OrderSuggestionRecruitWorkerTarget.omitsTrainedTiersWhenTechsLocked:
      final game = recruitWorkerInclusionTechLockedGame();
      final list = suggestRecruitWorkerOrders(
        recruitWorkerTestViewFor(game, 'p1'),
        game,
        recruitWorkerTestTopology,
        const Orders(),
      );
      expect(list.map((o) => o.targetTier).toList(), [WorkerTier.peasant]);
      for (final tier in recruitWorkerTestAllTiers.where(
        (t) => t != WorkerTier.peasant,
      )) {
        final candidate = RecruitWorkerOrder(targetTier: tier);
        expect(
          recruitWorkerTestEngineAccepts(
            game,
            const Orders(),
            'p1',
            candidate,
          ),
          isFalse,
          reason: '${tier.name} candidate rejected at the order engine '
              'because tech gate is locked',
        );
      }

    case OrderSuggestionRecruitWorkerTarget.omitsPeasantWhenFabricInsufficient:
      final game = recruitWorkerInclusionInsufficientFabricGame();
      final list = suggestRecruitWorkerOrders(
        recruitWorkerTestViewFor(game, 'p1'),
        game,
        recruitWorkerTestTopology,
        const Orders(),
      );
      expect(
        list.any((o) => o.targetTier == WorkerTier.peasant),
        isFalse,
        reason: 'peasant row needs 2 fabric',
      );

    case OrderSuggestionRecruitWorkerTarget.omitsApprenticeWhenTreasuryBelow200:
      final game = recruitWorkerInclusionLowTreasuryGame();
      final list = suggestRecruitWorkerOrders(
        recruitWorkerTestViewFor(game, 'p1'),
        game,
        recruitWorkerTestTopology,
        const Orders(),
      );
      expect(
        list.any((o) => o.targetTier == WorkerTier.apprentice),
        isFalse,
        reason: 'apprentice row needs 200 ducats; treasury == 100',
      );

    case OrderSuggestionRecruitWorkerTarget.omitsApprenticeWhenPeasantPoolEmpty:
      final game = recruitWorkerInclusionEmptyPeasantPoolGame();
      final list = suggestRecruitWorkerOrders(
        recruitWorkerTestViewFor(game, 'p1'),
        game,
        recruitWorkerTestTopology,
        const Orders(),
      );
      expect(
        list.any((o) => o.targetTier == WorkerTier.apprentice),
        isFalse,
        reason: 'apprentice row consumes 1 peasant',
      );

    case OrderSuggestionRecruitWorkerTarget.returnsAllFourTiersWhenFullyUnlocked:
      final game = recruitWorkerParityAllTiersGame();
      final list = suggestRecruitWorkerOrders(
        recruitWorkerTestViewFor(game, 'p1'),
        game,
        recruitWorkerTestTopology,
        const Orders(),
      );
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
          recruitWorkerTestEngineAccepts(
            game,
            const Orders(),
            'p1',
            candidate,
          ),
          isTrue,
          reason: 'engine accepts every emitted candidate (parity)',
        );
      }

    case OrderSuggestionRecruitWorkerTarget
        .peasantReservationExcludesApprenticeCandidate:
      final game = recruitWorkerParityPeasantReservationGame();
      final list = suggestRecruitWorkerOrders(
        recruitWorkerTestViewFor(game, 'p1'),
        game,
        recruitWorkerTestTopology,
        recruitWorkerParityPeasantReservationOrders,
      );
      expect(
        list.any((o) => o.targetTier == WorkerTier.apprentice),
        isFalse,
        reason:
            'peasant reservation ledger: pending apprentice already '
            'consumed the only peasant',
      );
      expect(
        list.any((o) => o.targetTier == WorkerTier.peasant),
        isTrue,
        reason: 'peasant recruit does not consume peasants',
      );

    case OrderSuggestionRecruitWorkerTarget.engineRoundTripParityPartialFixture:
      final game = recruitWorkerParityPartialTechFixtureGame();
      final list = suggestRecruitWorkerOrders(
        recruitWorkerTestViewFor(game, 'p1'),
        game,
        recruitWorkerTestTopology,
        const Orders(),
      );
      expect(
        list.map((o) => o.targetTier).toSet(),
        {WorkerTier.peasant, WorkerTier.apprentice},
      );
      for (final tier in recruitWorkerTestAllTiers) {
        final candidate = RecruitWorkerOrder(targetTier: tier);
        final inSuggestions = list.any(
          (o) => o.targetTier == candidate.targetTier,
        );
        final engineAccepts = recruitWorkerTestEngineAccepts(
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

    case OrderSuggestionRecruitWorkerTarget.emptyPlayerReturnsEmptyList:
      final game = recruitWorkerParityEmptyPlayerGame();
      final list = suggestRecruitWorkerOrders(
        recruitWorkerTestViewFor(game, 'p1'),
        game,
        recruitWorkerTestTopology,
        const Orders(),
      );
      expect(list, isEmpty);
      for (final tier in recruitWorkerTestAllTiers) {
        expect(
          recruitWorkerTestEngineAccepts(
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
  }
}
