// Topic-split case module (Refs #3997 Phase 8).
// Registered from the thin contract / barrel for this family.
// Pin/row coverage is preserved 1:1 from the former combined cases file.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void registerDiplomaticCandidateScoringSuppressionExpandBelowQuotaEarlyCasesTail() {
  group('computeDiplomaticCandidateScores suppression (part 2)', () {
    test(
      'stalledGpBlockerDeclareWarTarget skips mutual plateau when already at war',
      () {
        final game = Game(
          id: 'g-mutual-plateau-at-war',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 60,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
                for (var i = 0; i < 9; i++)
                  Province(
                    id: 'oldWorld|gp4_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp4',
                  ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp3', displayName: 'C', isHuman: false),
            Player(id: 'gp4', displayName: 'D', isHuman: false),
          ],
          diplomacyRelations: [
            const DiplomacyRelation(
              factionId1: 'gp3',
              factionId2: 'gp4',
              state: RelationState.atWar,
            ),
          ],
        );
        const snap = AIWorldSnapshot(
          playerId: 'gp3',
          threats: ThreatSummary(atWarWith: ['gp4']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 8,
            invadableProvinceIdsSorted: ['oldWorld|gp4_8'],
            adjacentOwnerFactionIdsSorted: ['gp4'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          stalledGpBlockerDeclareWarTarget(game: game, snapshot: snap),
          isNull,
        );
      },
    );

    test(
      'suppresses early declareWar on below-quota GP when attacker leads by 1+',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 9,
            provincesToVictory: 22,
            invadableProvinceIdsSorted: ['oldWorld|p30'],
            adjacentOwnerFactionIdsSorted: ['gp3'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-early-anti-dogpile',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 8,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
                for (var i = 0; i < 9; i++)
                  Province(
                    id: 'oldWorld|gp4_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp4',
                  ),
                const Province(
                  id: 'oldWorld|p30',
                  regionId: 'oldWorld',
                  ownerId: 'minor1',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp3', displayName: 'C', isHuman: false),
            Player(id: 'gp4', displayName: 'D', isHuman: false),
          ],
          minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        );
        const config = AIConfig(
          leaderId: 'henry',
          personalityId: 'henry',
          hiddenAgendaId: 'merchant',
        );
        final score = computeDiplomaticCandidateScores(
          DiplomaticCandidateScoringInput(
            candidates: const [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'gp3',
              ),
            ],
            nationId: 'gp4',
            game: game,
            snapshot: snap,
            config: config,
            primaryGoal: StrategicGoal.conquer,
          ),
        ).single;
        expect(score, 0);
      },
    );

  });
}
