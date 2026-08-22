import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../support/turn_news_digest_test_support.dart';
import 'last_turn_intelligence_digest_test_cases.dart';

void main() {
  group('buildLastTurnIntelligenceDigest', () {
    test(
      'Given third-party war and capture When persist Then world lines and JSON',
      () {
        const pid = 'oldWorld|p1';
        final start = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: RegionData(
              provinces: [
                const Province(
                  id: pid,
                  regionId: 'oldWorld',
                  ownerId: 'gp2',
                  displayName: 'Valois',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: lastTurnIntelThreeGps,
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp2',
              factionId2: 'gp3',
              state: RelationState.atPeace,
            ),
          ],
        );
        final end = start.copyWith(
          worldState: start.worldState.copyWith(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
            oldWorld: RegionData(
              provinces: [
                const Province(
                  id: pid,
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                  displayName: 'Valois',
                ),
              ],
            ),
          ),
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp2',
              factionId2: 'gp3',
              state: RelationState.atWar,
            ),
          ],
        );
        final news = buildTurnNewsDigestForComplete(start: start, end: end);
        final game = persistLastTurnIntelligenceDigest(
          start: start,
          end: news.game,
          worldNews: news.digest,
        );
        final digest = game.lastTurnIntelligenceDigest;
        expect(digest, isNotNull);
        expect(
          digest!.worldLines.any((l) => l.kind == IntelligenceWorldKind.war),
          isTrue,
        );
        expect(
          digest.worldLines.any(
            (l) =>
                l.kind == IntelligenceWorldKind.provinceCaptured &&
                l.provinceId == pid,
          ),
          isTrue,
        );
        expect(LastTurnIntelligenceDigest.fromJson(digest.toJson()), digest);
      },
    );

    registerLastTurnIntelSpyCases();

    test('Given new digest When persist Then previous digest replaced', () {
      final start = turnNewsMinimalGame(turn: 2).copyWith(
        lastTurnIntelligenceDigest: const LastTurnIntelligenceDigest(
          resolvedTurnNumber: 1,
          worldLines: [IntelligenceWorldLine(kind: IntelligenceWorldKind.war)],
        ),
      );
      final end = turnNewsMinimalGame(turn: 3);
      final game = persistLastTurnIntelligenceDigest(
        start: start,
        end: end,
        worldNews: const TurnNewsDigest(resolvedTurnNumber: 2, lines: []),
      );
      expect(game.lastTurnIntelligenceDigest!.resolvedTurnNumber, 2);
      expect(game.lastTurnIntelligenceDigest!.worldLines, isEmpty);
    });

    test('Given victory When persist Then digest unchanged', () {
      final start = turnNewsMinimalGame(turn: 2);
      final end = start.copyWith(
        victory: const VictoryState(
          winnerPlayerId: 'gp1',
          type: VictoryType.military,
          turnNumber: 2,
        ),
      );
      final news = buildTurnNewsDigestForComplete(start: start, end: end);
      final game = persistLastTurnIntelligenceDigest(
        start: start,
        end: news.game,
        worldNews: news.digest,
      );
      expect(game.lastTurnIntelligenceDigest, isNull);
    });
  });
}
