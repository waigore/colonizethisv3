// Case bodies for `diplomatic_candidate_scoring_test.dart` (Refs #3997 Phase 8).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'diplomatic_candidate_scoring_core_later_cases_tail_cases.dart';

void registerDiplomaticCandidateScoringCoreLaterCases() {
  group('computeDiplomaticCandidateScores', () {
test(
      'peacemaker scores declareWar on minor when behind victory pace despite neutral relation',
      () {
        final game = Game(
          id: 'g-minor-war-pace',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|p2',
                  regionId: 'oldWorld',
                  ownerId: 'minor1',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'minor1',
              score: 50,
              level: RelationLevel.neutral,
              state: RelationState.atPeace,
            ),
          ],
        );
        const candidate = [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'minor1',
          ),
        ];
        const config = AIConfig(
          leaderId: 'victoria',
          personalityId: 'victoria',
          hiddenAgendaId: 'peacemaker',
        );
        const behindPaceSnapshot = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            provincesToVictory: 24,
            invadableProvinceIdsSorted: ['oldWorld|p2'],
          ),
          economy: EconomySummary(),
          relations: {},
        );
        const nearVictorySnapshot = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(provincesToVictory: 5),
          economy: EconomySummary(),
          relations: {},
        );
        final behindScore = computeDiplomaticCandidateScores(
          DiplomaticCandidateScoringInput(
            candidates: candidate,
            nationId: 'gp1',
            game: game,
            snapshot: behindPaceSnapshot,
            config: config,
          ),
        ).single;
        final nearVictoryScore = computeDiplomaticCandidateScores(
          DiplomaticCandidateScoringInput(
            candidates: candidate,
            nationId: 'gp1',
            game: game,
            snapshot: nearVictorySnapshot,
            config: config,
          ),
        ).single;
        expect(behindScore, greaterThan(0));
        expect(nearVictoryScore, 0);
      },
    );

test(
      'henry scores adjacent minor declareWar higher than non-adjacent minor when behind pace',
      () {
        final game = Game(
          id: 'g-adj-minor',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|p2',
                  regionId: 'oldWorld',
                  ownerId: 'minor1',
                ),
                Province(
                  id: 'oldWorld|p9',
                  regionId: 'oldWorld',
                  ownerId: 'minor6',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'M1'),
            MinorNation(id: 'minor6', displayName: 'M6'),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'minor1',
              score: 50,
              level: RelationLevel.neutral,
              state: RelationState.atPeace,
            ),
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'minor6',
              score: 50,
              level: RelationLevel.neutral,
              state: RelationState.atPeace,
            ),
          ],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
            TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
            TopologyNode(id: 'p9', regionId: 'oldWorld', type: TopologyNodeType.province),
          ],
          edges: const [
            TopologyEdge(id1: 'p1', id2: 'p2'),
          ],
        );
        const config = AIConfig(
          leaderId: 'henry',
          personalityId: 'henry',
          hiddenAgendaId: 'merchant',
        );
        final snap = AIWorldSnapshot.fromPlayerView(
          buildPlayerView(game, topology, 'gp1'),
          topology: topology,
        );
        final adjacentScore = computeDiplomaticCandidateScores(
          DiplomaticCandidateScoringInput(
            candidates: const [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'minor1',
              ),
            ],
            nationId: 'gp1',
            game: game,
            snapshot: snap,
            config: config,
            primaryGoal: StrategicGoal.trade,
          ),
        ).single;
        final distantScore = computeDiplomaticCandidateScores(
          DiplomaticCandidateScoringInput(
            candidates: const [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'minor6',
              ),
            ],
            nationId: 'gp1',
            game: game,
            snapshot: snap,
            config: config,
            primaryGoal: StrategicGoal.trade,
          ),
        ).single;
        expect(adjacentScore, greaterThan(distantScore));
        expect(
          adjacentScore - distantScore,
          greaterThanOrEqualTo(kDeclareWarAdjacentOwnerBonus),
        );
        expect(distantScore, kDeclareWarNonAdjacentSuppressedScore);
      },
    );
  });

  registerDiplomaticCandidateScoringCoreLaterCasesTail();
}
