import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_fixtures.dart';

void main() {
  late Game baseGame;

  setUp(() {
    baseGame = TestFixtures.minimalGame(
      id: 'g1',
      players: [Player(id: 'gp1', displayName: 'A', isHuman: true)],
    );
  });

  group('TurnResolutionResult', () {
    test('TurnResolutionComplete holds game and optional digest', () {
      final result = TurnResolutionComplete(
        baseGame,
        turnNewsDigest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
      );
      expect(result.game, baseGame);
      expect(result.turnNewsDigest, isNotNull);
    });

    test('TurnResolutionPendingOvertures holds game and list', () {
      final offers = [
        OvertureOffer(
          offererGpId: 'gp1',
          targetFactionId: 'gp2',
          stage: OvertureStage.embassy,
        ),
      ];
      final result = TurnResolutionPendingOvertures(
        game: baseGame,
        pendingOvertures: offers,
      );
      expect(result.game, baseGame);
      expect(result.pendingOvertures, offers);
    });

    test('TurnResolutionPendingIntervention holds game and list', () {
      final prompts = [
        InterventionPrompt(
          aggressorGpId: 'gp2',
          defenderMinorOrTribeId: 'minor1',
          interveningGpId: 'gp1',
        ),
      ];
      final result = TurnResolutionPendingIntervention(
        game: baseGame,
        pendingInterventions: prompts,
      );
      expect(result.game, baseGame);
      expect(result.pendingInterventions, prompts);
    });

    test('TurnResolutionPendingCallToArms holds game and list', () {
      final pending = [
        CallToArmsPending(
          allyGpId: 'gp1',
          defenderGpId: 'gp2',
          aggressorGpId: 'gp3',
        ),
      ];
      final result = TurnResolutionPendingCallToArms(
        game: baseGame,
        pendingCallToArms: pending,
      );
      expect(result.game, baseGame);
      expect(result.pendingCallToArms, pending);
    });
  });

  group('TurnResolutionResult.game (sealed base getter)', () {
    test('exposes game via base type for TurnResolutionComplete', () {
      final TurnResolutionResult result = TurnResolutionComplete(baseGame);
      expect(result.game, same(baseGame));
    });

    test('exposes game via base type for TurnResolutionPendingOvertures', () {
      final TurnResolutionResult result = TurnResolutionPendingOvertures(
        game: baseGame,
        pendingOvertures: const [
          OvertureOffer(
            offererGpId: 'gp1',
            targetFactionId: 'minor1',
            stage: OvertureStage.tradeConsulate,
          ),
        ],
      );
      expect(result.game, same(baseGame));
    });

    test(
      'exposes game via base type for TurnResolutionPendingIntervention',
      () {
        final TurnResolutionResult result = TurnResolutionPendingIntervention(
          game: baseGame,
          pendingInterventions: const [
            InterventionPrompt(
              aggressorGpId: 'gp2',
              defenderMinorOrTribeId: 'minor1',
              interveningGpId: 'gp1',
            ),
          ],
        );
        expect(result.game, same(baseGame));
      },
    );

    test('exposes game via base type for TurnResolutionPendingCallToArms', () {
      final TurnResolutionResult result = TurnResolutionPendingCallToArms(
        game: baseGame,
        pendingCallToArms: const [
          CallToArmsPending(
            allyGpId: 'gp1',
            defenderGpId: 'gp2',
            aggressorGpId: 'gp3',
          ),
        ],
      );
      expect(result.game, same(baseGame));
    });
  });

  group('requireTurnResolutionComplete', () {
    test('returns game for TurnResolutionComplete', () {
      final result = TurnResolutionComplete(baseGame);
      expect(requireTurnResolutionComplete(result), same(baseGame));
    });

    test('throws StateError with overture hint for pending overtures', () {
      final result = TurnResolutionPendingOvertures(
        game: baseGame,
        pendingOvertures: const [
          OvertureOffer(
            offererGpId: 'gp1',
            targetFactionId: 'minor1',
            stage: OvertureStage.tradeConsulate,
          ),
        ],
      );
      expect(
        () => requireTurnResolutionComplete(result),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('resumeTurnResolutionWithOvertureDecisions'),
          ),
        ),
      );
    });

    test(
      'throws StateError with intervention hint for pending intervention',
      () {
        final result = TurnResolutionPendingIntervention(
          game: baseGame,
          pendingInterventions: const [
            InterventionPrompt(
              aggressorGpId: 'gp2',
              defenderMinorOrTribeId: 'minor1',
              interveningGpId: 'gp1',
            ),
          ],
        );
        expect(
          () => requireTurnResolutionComplete(result),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('resumeTurnResolutionWithInterventionDecisions'),
            ),
          ),
        );
      },
    );

    test(
      'throws StateError with call-to-arms hint for pending call to arms',
      () {
        final result = TurnResolutionPendingCallToArms(
          game: baseGame,
          pendingCallToArms: const [
            CallToArmsPending(
              allyGpId: 'gp1',
              defenderGpId: 'gp2',
              aggressorGpId: 'gp3',
            ),
          ],
        );
        expect(
          () => requireTurnResolutionComplete(result),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('resumeTurnResolutionWithCallToArmsDecisions'),
            ),
          ),
        );
      },
    );
  });
}
