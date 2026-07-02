import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

/// Focused regression coverage for the consolidated pending-human-decision flow
/// (Refs #3562 AC3). The overture, FTP, intervention, and call-to-arms
/// resolvers now share one control-flow shape: the human-control check runs
/// *before* any decision lookup, so a supplied decision is honoured only for a
/// human-controlled counterpart, and AI-controlled counterparts always resolve
/// by rule. These tests assert that contract directly rather than relying on
/// the indirect coverage in the per-resolver suites.
void main() {
  Orders _orders(DiplomaticOrderType type, {OvertureStage? stage}) => Orders(
    diplomaticOrdersByPlayerId: {
      'gp1': [
        DiplomaticOrder(
          type: type,
          targetFactionId: 'gp2',
          overtureStage: stage,
        ),
      ],
    },
  );

  group('overture: consistent pending-human-decision flow', () {
    test(
      'human target with no decision suspends; resume applies the decision',
      () {
        final game = twoGpPendingFlowGame(
          targetHuman: true,
          score: 50,
          gp1Treasury: overtureConsulateCost + 100,
        );
        final orders = _orders(
          DiplomaticOrderType.establishOverture,
          stage: OvertureStage.tradeConsulate,
        );

        final pending = resolveDiplomacyPhase(game, orders);
        expect(pending.isPending, isTrue);
        expect(pending.pendingOvertures, isNotNull);
        expect(pending.pendingOvertures!.single.targetFactionId, 'gp2');

        final resumed = resolveDiplomacyPhase(
          game,
          orders,
          overtureDecisions: const [
            OvertureDecision(
              offererGpId: 'gp1',
              targetFactionId: 'gp2',
              stage: OvertureStage.tradeConsulate,
              accepted: true,
            ),
          ],
        );
        expect(resumed.isPending, isFalse);
        expect(getOverture(resumed.game, 'gp1', 'gp2'), isNotNull);
      },
    );

    test(
      'AI target resolves by rule and ignores a supplied accept decision',
      () {
        // Score below neutral -> AI target rejects by rule. The accept decision
        // (only valid on the human resume path) must not be honoured for an AI
        // target now that the human-control check gates the decision lookup.
        final game = twoGpPendingFlowGame(
          targetHuman: false,
          score: relationScoreNeutral - 10,
          gp1Treasury: overtureConsulateCost + 100,
        );
        final orders = _orders(
          DiplomaticOrderType.establishOverture,
          stage: OvertureStage.tradeConsulate,
        );

        final result = resolveDiplomacyPhase(
          game,
          orders,
          overtureDecisions: const [
            OvertureDecision(
              offererGpId: 'gp1',
              targetFactionId: 'gp2',
              stage: OvertureStage.tradeConsulate,
              accepted: true,
            ),
          ],
        );
        expect(result.isPending, isFalse);
        expect(getOverture(result.game, 'gp1', 'gp2'), isNull);
      },
    );
  });

  group('ftp: consistent pending-human-decision flow', () {
    List<OvertureState> _embassyPair() => const [
      OvertureState(gpId: 'gp1', targetId: 'gp2', stage: OvertureStage.embassy),
      OvertureState(gpId: 'gp2', targetId: 'gp1', stage: OvertureStage.embassy),
    ];

    test(
      'human target with no decision suspends; resume applies the decision',
      () {
        final game = twoGpPendingFlowGame(
          targetHuman: true,
          score: 70,
          overtures: _embassyPair(),
        );
        final orders = _orders(DiplomaticOrderType.establishFtp);

        final pending = resolveDiplomacyPhase(game, orders);
        expect(pending.isPending, isTrue);
        expect(pending.pendingFtpOffers, isNotNull);
        expect(pending.pendingFtpOffers!.single.targetGpId, 'gp2');

        final resumed = resolveDiplomacyPhase(
          game,
          orders,
          ftpDecisions: const [
            FtpDecision(proposerGpId: 'gp1', targetGpId: 'gp2', accepted: true),
          ],
        );
        expect(resumed.isPending, isFalse);
        expect(hasFtpPartnership(resumed.game, 'gp1', 'gp2'), isTrue);
      },
    );

    test(
      'AI target resolves by rule and ignores a supplied refuse decision',
      () {
        // Embassy both ways and score >= min -> AI target accepts by rule. The
        // refuse decision must not be honoured for an AI target; the human-first
        // ordering means the AI rule governs.
        final game = twoGpPendingFlowGame(
          targetHuman: false,
          score: 70,
          overtures: _embassyPair(),
        );
        final orders = _orders(DiplomaticOrderType.establishFtp);

        final result = resolveDiplomacyPhase(
          game,
          orders,
          ftpDecisions: const [
            FtpDecision(
              proposerGpId: 'gp1',
              targetGpId: 'gp2',
              accepted: false,
            ),
          ],
        );
        expect(result.isPending, isFalse);
        expect(hasFtpPartnership(result.game, 'gp1', 'gp2'), isTrue);
      },
    );
  });
}
