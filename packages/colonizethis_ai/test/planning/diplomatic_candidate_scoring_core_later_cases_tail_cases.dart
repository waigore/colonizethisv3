// Case bodies for `diplomatic_candidate_scoring_test.dart` (Refs #3997 Phase 8).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void registerDiplomaticCandidateScoringCoreLaterCasesTail() {
  group('computeDiplomaticCandidateScores', () {
test(
      'behind pace suppresses declareWar on non-adjacent minor when adjacent GP exists',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(weakNeighbors: ['gp2']),
          conquest: ConquestSummary(
            provincesToVictory: 24,
            adjacentOwnerFactionIdsSorted: ['gp2'],
          ),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-suppress',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'M1'),
          ],
        );
        const config = AIConfig(
          leaderId: 'henry',
          personalityId: 'henry',
          hiddenAgendaId: 'merchant',
        );
        final minorScore = computeDiplomaticCandidateScores(
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
          ),
        ).single;
        final gpScore = computeDiplomaticCandidateScores(
          DiplomaticCandidateScoringInput(
            candidates: const [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'gp2',
              ),
            ],
            nationId: 'gp1',
            game: game,
            snapshot: snap,
            config: config,
          ),
        ).single;
        expect(minorScore, kDeclareWarNonAdjacentSuppressedScore);
        expect(gpScore, kDeclareWarNonAdjacentSuppressedScore);
      },
    );

test(
      'behind pace suppresses declareWar on adjacent GP even with high war desire',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: const OpportunitySummary(),
          conquest: ConquestSummary(
            provincesToVictory: 24,
            adjacentOwnerFactionIdsSorted: ['gp2'],
          ),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-suppress-strong-gp',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|p1_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp1',
                  ),
                const Province(
                  id: 'oldWorld|p2',
                  regionId: 'oldWorld',
                  ownerId: 'gp2',
                ),
              ],
              units: [
                for (var i = 0; i < 6; i++)
                  Unit(
                    id: 'a$i',
                    type: 'grenadiers',
                    ownerId: 'gp1',
                    locationProvinceId: 'oldWorld|p1_0',
                  ),
                Unit(
                  id: 'b1',
                  type: 'grenadiers',
                  ownerId: 'gp2',
                  locationProvinceId: 'oldWorld|p2',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              score: 10,
              level: RelationLevel.hostile,
              state: RelationState.atPeace,
            ),
          ],
        );
        const config = AIConfig(
          leaderId: 'henry',
          personalityId: 'henry',
          hiddenAgendaId: 'merchant',
        );
        final gpScore = computeDiplomaticCandidateScores(
          DiplomaticCandidateScoringInput(
            candidates: const [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'gp2',
              ),
            ],
            nationId: 'gp1',
            game: game,
            snapshot: snap,
            config: config,
          ),
        ).single;
        expect(gpScore, kDeclareWarNonAdjacentSuppressedScore);
      },
    );
  });
}
