// Colonial-phase GP peace target cases (Refs #4310 Slice D topic-split).
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void registerObserverGoalPhaseGpPeaceTargetsColonialCases() {
  group('colonialPhaseGpPeaceTargets', () {
    test('peaces non-blocker GP when two GPs at war in colonial phase', () {
      final game = Game(
        id: 'g-colonial-peace',
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 110, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: [
              const Province(
                id: 'newWorld|nw1',
                regionId: 'newWorld',
                ownerId: 'gp2',
              ),
              const Province(
                id: 'newWorld|nw2',
                regionId: 'newWorld',
                ownerId: 'tribe1',
              ),
            ],
          ),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: false),
          Player(id: 'gp2', displayName: 'P2', isHuman: false),
        ],
        tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
        minorNations: const [],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: const ThreatSummary(atWarWith: ['gp2', 'gp3']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 11),
        colonial: ColonialSummary(
          invadableNewWorldProvinceIdsSorted: ['newWorld|nw1', 'newWorld|nw2'],
          adjacentNewWorldOwnerFactionIdsSorted: ['gp2', 'tribe1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        colonialPhaseGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
      );
      final gameWithGp3 = game.copyWith(
        players: [
          ...game.players,
          const Player(id: 'gp3', displayName: 'P3', isHuman: false),
        ],
      );
      expect(
        colonialPhaseGpPeaceTargets(game: gameWithGp3, snapshot: snapshot),
        ['gp3'],
      );
    });
  });

  group('COLONIAL allows NW tribe declareWar scoring', () {
    test('tribe declare-war is not suppressed at OW quota', () {
      final game = Game(
        id: 'g-colonial-declare',
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 110, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: [
              const Province(
                id: 'newWorld|nw1',
                regionId: 'newWorld',
                ownerId: 'tribe1',
              ),
            ],
          ),
        ),
        players: const [Player(id: 'gp1', displayName: 'P1', isHuman: false)],
        tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
        minorNations: const [],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 11),
        colonial: ColonialSummary(
          invadableNewWorldProvinceIdsSorted: ['newWorld|nw1'],
          adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      final scores = computeDiplomaticCandidateScores(
        DiplomaticCandidateScoringInput(
          game: game,
          snapshot: snapshot,
          nationId: 'gp1',
          config: const AIConfig(
            leaderId: 'henry',
            personalityId: 'henry',
            hiddenAgendaId: 'merchant',
          ),
          candidates: const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'tribe1',
            ),
          ],
          primaryGoal: StrategicGoal.conquer,
        ),
      );
      expect(scores.single, greaterThan(0));
    });
  });

  group('COLONIAL personality colonial acquisition', () {
    test('napoleon ranks declareWar above establishOverture henry reverses',
        () {
      final game = Game(
        id: 'g-colonial-personality',
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 110, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: [
              const Province(
                id: 'newWorld|nw1',
                regionId: 'newWorld',
                ownerId: 'tribe1',
              ),
            ],
          ),
        ),
        players: const [Player(id: 'gp1', displayName: 'P1', isHuman: false)],
        tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
        minorNations: const [],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'tribe1',
            state: RelationState.atPeace,
            score: 60,
          ),
        ],
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'tribe1',
            stage: OvertureStage.embassy,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 11),
        colonial: ColonialSummary(
          invadableNewWorldProvinceIdsSorted: ['newWorld|nw1'],
          adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          preferredColonialTargetFactionIdsSorted: ['tribe1'],
        ),
        economy: EconomySummary(),
        relations: {
          'tribe1': DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'tribe1',
            state: RelationState.atPeace,
            score: 60,
          ),
        },
      );
      const candidates = [
        const DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'tribe1',
        ),
        const DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'tribe1',
        ),
      ];

      DiplomaticOrderType topTypeFor(String personalityId) {
        final scores = computeDiplomaticCandidateScores(
          DiplomaticCandidateScoringInput(
            game: game,
            snapshot: snapshot,
            nationId: 'gp1',
            config: AIConfig(
              leaderId: personalityId,
              personalityId: personalityId,
              hiddenAgendaId: 'merchant',
            ),
            candidates: candidates,
            primaryGoal: StrategicGoal.conquer,
          ),
        );
        var bestIdx = 0;
        for (var i = 1; i < scores.length; i++) {
          if (scores[i] > scores[bestIdx]) {
            bestIdx = i;
          }
        }
        return candidates[bestIdx].type;
      }

      expect(
        topTypeFor('napoleon'),
        DiplomaticOrderType.declareWar,
      );
      expect(
        topTypeFor('henry'),
        DiplomaticOrderType.establishOverture,
      );
    });
  });
}
