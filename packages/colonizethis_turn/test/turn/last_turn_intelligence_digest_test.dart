import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../support/turn_news_digest_test_support.dart';

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
          players: _threeGps,
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

    test(
      'Given no spy in France When France unlocks tech and fights Then no spy block',
      () {
        final start = _franceSpainGame(turn: 2, spyInFrance: false);
        final end = _franceSpainGame(
          turn: 3,
          spyInFrance: false,
          franceTech: const {kTechIdCropRotation: true},
        );
        final news = const TurnNewsDigest(resolvedTurnNumber: 2, lines: []);
        final digest = buildLastTurnIntelligenceDigest(
          start: start,
          end: end,
          worldNews: news,
          turnEvents: const [
            CombatResultEvent(
              provinceId: 'oldWorld|fr1',
              attackerId: 'france',
              defenderId: 'gp3',
              winnerId: 'france',
              turnNumber: 2,
            ),
          ],
        );
        expect(digest.spyReportsFor('gp1'), isEmpty);
      },
    );

    test(
      'Given spy remaining in France When France techs and declares war Then spy block',
      () {
        final start = _franceSpainGame(turn: 2, spyInFrance: true);
        final end =
            _franceSpainGame(
              turn: 3,
              spyInFrance: true,
              franceTech: const {kTechIdCropRotation: true},
            ).copyWith(
              diplomaticHistoryEvents: const [
                DiplomaticEvent(
                  turn: 2,
                  intraTurnIndex: 0,
                  type: DiplomaticEventType.declareWar,
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
        final block = digest.spyReportsFor('gp1').single;
        expect(block.courtFactionId, 'france');
        expect(
          block.lines.any(
            (l) =>
                l.kind == IntelligenceSpyKind.diplomatic &&
                l.diplomaticType == DiplomaticEventType.declareWar &&
                l.toFactionId == 'gp3',
          ),
          isTrue,
        );
        expect(
          block.lines.any(
            (l) =>
                l.kind == IntelligenceSpyKind.researchComplete &&
                l.techId == kTechIdCropRotation,
          ),
          isTrue,
        );
        expect(block.lines.any((l) => l.techId == 'hiddenAgenda'), isFalse);
      },
    );

    test(
      'Given last spy left France When digest builds Then France spy omitted',
      () {
        final start = _franceSpainGame(turn: 2, spyInFrance: true);
        final end = _franceSpainGame(turn: 3, spyInFrance: false).copyWith(
          diplomaticHistoryEvents: const [
            DiplomaticEvent(
              turn: 2,
              intraTurnIndex: 0,
              type: DiplomaticEventType.declareWar,
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
        expect(digest.spyReportsFor('gp1'), isEmpty);
      },
    );

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

const _threeGps = [
  Player(id: 'gp1', displayName: 'England', isHuman: true, treasury: 0),
  Player(id: 'gp2', displayName: 'Spain', isHuman: false, treasury: 0),
  Player(id: 'gp3', displayName: 'France', isHuman: false, treasury: 0),
];

Game _franceSpainGame({
  required int turn,
  required bool spyInFrance,
  Map<String, bool> franceTech = const {},
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turn),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: 'oldWorld|fr1',
            regionId: 'oldWorld',
            ownerId: 'france',
            displayName: 'Paris',
          ),
        ],
        units: [
          if (spyInFrance)
            Unit(
              id: 'spy1',
              type: kUnitTypeSpy,
              ownerId: 'gp1',
              locationProvinceId: 'oldWorld|fr1',
            ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      const Player(
        id: 'gp1',
        displayName: 'England',
        isHuman: true,
        treasury: 0,
      ),
      Player(
        id: 'france',
        displayName: 'France',
        isHuman: false,
        treasury: 0,
        techUnlocked: franceTech,
      ),
      const Player(
        id: 'gp3',
        displayName: 'Spain',
        isHuman: false,
        treasury: 0,
      ),
    ],
  );
}
