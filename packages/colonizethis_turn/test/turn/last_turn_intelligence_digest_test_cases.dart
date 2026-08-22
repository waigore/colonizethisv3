import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

const lastTurnIntelThreeGps = [
  Player(id: 'gp1', displayName: 'England', isHuman: true, treasury: 0),
  Player(id: 'gp2', displayName: 'Spain', isHuman: false, treasury: 0),
  Player(id: 'gp3', displayName: 'France', isHuman: false, treasury: 0),
];

Game franceSpainGame({
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

void registerLastTurnIntelSpyCases() {
  test(
    'Given no spy in France When France unlocks tech and fights Then no spy block',
    () {
      final start = franceSpainGame(turn: 2, spyInFrance: false);
      final end = franceSpainGame(
        turn: 3,
        spyInFrance: false,
        franceTech: const {kTechIdCropRotation: true},
      );
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
      expect(digest.spyReportsFor('gp1'), isEmpty);
    },
  );

  test(
    'Given spy remaining in France When France techs and declares war Then spy block',
    () {
      final start = franceSpainGame(turn: 2, spyInFrance: true);
      final end =
          franceSpainGame(
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
      final start = franceSpainGame(turn: 2, spyInFrance: true);
      final end = franceSpainGame(turn: 3, spyInFrance: false).copyWith(
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
