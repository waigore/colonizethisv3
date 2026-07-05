import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/src/turn/turn_resolution_result.dart';

void main() {
  final game = TestFixtures.minimalGame(id: 'result-test');

  group('gameFromTurnResolutionResult', () {
    test('reads game from TurnResolutionComplete', () {
      const digest = TurnNewsDigest(resolvedTurnNumber: 1, lines: []);
      final result = TurnResolutionComplete(game, turnNewsDigest: digest);
      expect(gameFromTurnResolutionResult(result), same(game));
      expect(result.turnNewsDigest, digest);
    });

    test('reads game from TurnResolutionPendingOvertures', () {
      const offers = [
        OvertureOffer(
          offererGpId: 'gp1',
          targetFactionId: 'gp2',
          stage: OvertureStage.tradeConsulate,
        ),
      ];
      final result = TurnResolutionPendingOvertures(
        game: game,
        pendingOvertures: offers,
      );
      expect(gameFromTurnResolutionResult(result), same(game));
      expect(result.pendingOvertures, offers);
    });

    test('reads game from TurnResolutionPendingFtp', () {
      const offers = [
        FtpOffer(proposerGpId: 'gp1', targetGpId: 'gp2'),
      ];
      final result = TurnResolutionPendingFtp(
        game: game,
        pendingFtpOffers: offers,
      );
      expect(gameFromTurnResolutionResult(result), same(game));
      expect(result.pendingFtpOffers, offers);
    });

    test('reads game from TurnResolutionPendingIntervention', () {
      const prompts = [
        InterventionPrompt(
          aggressorGpId: 'gp2',
          defenderMinorOrTribeId: 'minor1',
          interveningGpId: 'gp1',
        ),
      ];
      final result = TurnResolutionPendingIntervention(
        game: game,
        pendingInterventions: prompts,
      );
      expect(gameFromTurnResolutionResult(result), same(game));
      expect(result.pendingInterventions, prompts);
    });

    test('reads game from TurnResolutionPendingCallToArms', () {
      const pending = [
        CallToArmsPending(
          allyGpId: 'gp1',
          defenderGpId: 'gp2',
          aggressorGpId: 'gp3',
        ),
      ];
      final result = TurnResolutionPendingCallToArms(
        game: game,
        pendingCallToArms: pending,
      );
      expect(gameFromTurnResolutionResult(result), same(game));
      expect(result.pendingCallToArms, pending);
    });
  });
}
