// Alliance / combat digest cases (Refs #4740 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'last_turn_intelligence_digest_test_cases.dart';

void registerLastTurnIntelAllianceCombatCases() {
  test(
    'Given alliance formed When digest builds Then world lines include alliance',
    () {
      final start = franceSpainGame(turn: 2, spyInFrance: false);
      final end = franceSpainGame(turn: 3, spyInFrance: false).copyWith(
        diplomaticHistoryEvents: const [
          DiplomaticEvent(
            turn: 2,
            intraTurnIndex: 0,
            type: DiplomaticEventType.allianceFormed,
            participants: {'france', 'gp3'},
            fromFactionId: 'france',
            toFactionId: 'gp3',
          ),
        ],
      );
      final digest = buildLastTurnIntelligenceDigest(
        start: start,
        end: end,
        worldNews: const TurnNewsDigest(resolvedTurnNumber: 2, lines: []),
      );
      expect(
        digest.worldLines.any(
          (l) =>
              l.kind == IntelligenceWorldKind.allianceFormed &&
              l.factionIdA == 'france' &&
              l.factionIdB == 'gp3',
        ),
        isTrue,
      );
    },
  );

  test('Given spy remaining When France fights Then spy combat line', () {
    final start = franceSpainGame(turn: 2, spyInFrance: true);
    final end = franceSpainGame(turn: 3, spyInFrance: true);
    final digest = buildLastTurnIntelligenceDigest(
      start: start,
      end: end,
      worldNews: const TurnNewsDigest(resolvedTurnNumber: 2, lines: []),
      turnEvents: const [
        CombatResultEvent(
          provinceId: 'oldWorld|fr1',
          attackerId: 'france',
          defenderId: 'gp3',
          outcomeName: 'attackerVictory',
          winnerId: 'france',
          turnNumber: 2,
        ),
      ],
    );
    expect(
      digest
          .spyReportsFor('gp1')
          .single
          .lines
          .any(
            (l) =>
                l.kind == IntelligenceSpyKind.combat &&
                l.provinceId == 'oldWorld|fr1',
          ),
      isTrue,
    );
  });
}
