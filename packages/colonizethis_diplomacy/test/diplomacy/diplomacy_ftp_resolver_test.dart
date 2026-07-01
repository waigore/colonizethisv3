import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show DealMatcher;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import '../support/diplomacy_game_fixtures.dart';

void main() {
  group('processFtpProposals', () {
    test('establishes FTP when embassy both ways and score >= 65', () {
      final game = gpGpEmbassyGame();
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.establishFtp,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );

      final after = resolveDiplomacyPhase(game, orders).game;
      expect(hasFtpPartnership(after, 'gp1', 'gp2'), isTrue);
      expect(
        after.diplomaticHistoryEvents.any(
          (e) => e.type == DiplomaticEventType.ftpFormed,
        ),
        isTrue,
      );
    });

    test('AI target rejects when score below 65', () {
      final game = gpGpEmbassyGame(relationScore: 60);
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.establishFtp,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );

      final after = resolveDiplomacyPhase(game, orders).game;
      expect(hasFtpPartnership(after, 'gp1', 'gp2'), isFalse);
    });

    test('human target suspends until FtpDecision supplied', () {
      final game = gpGpEmbassyGame(
        id: 'ftp-human',
        turnNumber: 1,
        gp2Human: true,
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.establishFtp,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );

      final pending = resolveDiplomacyPhase(game, orders);
      expect(pending.pendingFtpOffers, isNotNull);
      expect(pending.pendingFtpOffers!.single.targetGpId, 'gp2');

      final accepted = resolveDiplomacyPhase(
        pending.game,
        orders,
        ftpDecisions: const [
          FtpDecision(proposerGpId: 'gp1', targetGpId: 'gp2', accepted: true),
        ],
      ).game;
      expect(hasFtpPartnership(accepted, 'gp1', 'gp2'), isTrue);
    });
  });

  group('FTP break conditions', () {
    test('war clears FTP between the warring GPs', () {
      var game = gpGpEmbassyGame(
        existingFtpKeys: {pairKey('gp1', 'gp2')},
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );

      game = resolveDiplomacyPhase(game, orders).game;
      expect(hasFtpPartnership(game, 'gp1', 'gp2'), isFalse);
      expect(
        game.diplomaticHistoryEvents.any(
          (e) => e.type == DiplomaticEventType.ftpBroken,
        ),
        isTrue,
      );
    });

    test('embassy loss clears FTP', () {
      final game = gpGpEmbassyGame(
        existingFtpKeys: {pairKey('gp1', 'gp2')},
      );
      final withoutEmbassy = game.copyWith(
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'gp2',
            stage: OvertureStage.tradeConsulate,
          ),
          OvertureState(
            gpId: 'gp2',
            targetId: 'gp1',
            stage: OvertureStage.embassy,
          ),
        ],
      );

      final after = breakFtpOnEmbassyLoss(withoutEmbassy, 3);
      expect(hasFtpPartnership(after, 'gp1', 'gp2'), isFalse);
    });
  });

  group('ftpPairKeysFromGame + DealMatcher', () {
    test('FTP pair from game state fills before non-FTP at same priority', () {
      final game = gpGpEmbassyGame(
        existingFtpKeys: {pairKey('sellerFtp', 'buyerFtp')},
      );
      final ftpKeys = ftpPairKeysFromGame(game);

      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'sellerFtp': [matcherOffer('timber', 10, priority: 1)],
            'sellerOther': [matcherOffer('timber', 10, priority: 1)],
          },
          bidsByFactionId: {
            'buyerFtp': [matcherBid('timber', 10, priority: 1)],
            'buyerOther': [matcherBid('timber', 10, priority: 1)],
          },
          tradeCapacityByFactionId: const {'buyerFtp': 20, 'buyerOther': 20},
          ftpPairKeys: ftpKeys,
        ),
      );

      expect(result.filledDeals.length, 2);
      expect(result.filledDeals.first.sellerFactionId, 'sellerFtp');
      expect(result.filledDeals.first.buyerFactionId, 'buyerFtp');
      expect(result.filledDeals.first.isFtpMatch, isTrue);
    });
  });
}
