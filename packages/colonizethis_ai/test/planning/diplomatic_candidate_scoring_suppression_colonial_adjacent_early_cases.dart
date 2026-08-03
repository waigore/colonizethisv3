// Topic-split case module (Refs #3997 Phase 8).
// Registered from the thin contract / barrel for this family.
// Pin/row coverage is preserved 1:1 from the former combined cases file.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';


void registerDiplomaticScoringSuppressionColonialAdjacentEarlyCases() {
  group('computeDiplomaticCandidateScores suppression (part 3)', () {
    test(
      'offerPeace boosts consolidate-gains sole GP war victim',
      () {
        final game = Game(
          id: 'g-offer-peace-consolidate',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 60,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 12; i++)
                  Province(
                    id: 'oldWorld|gp4_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp4',
                  ),
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp4', displayName: 'P4', isHuman: false),
            Player(id: 'gp3', displayName: 'P3', isHuman: false),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp4',
              factionId2: 'gp3',
              state: RelationState.atWar,
              score: 30,
            ),
          ],
        );
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(atWarWith: ['gp3']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 12,
            provincesToVictory: 18,
            invadableProvinceIdsSorted: const [],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
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
                type: DiplomaticOrderType.offerPeace,
                targetFactionId: 'gp3',
              ),
            ],
            nationId: 'gp4',
            game: game,
            snapshot: snap,
            config: config,
          ),
        ).single;
        expect(
          score,
          greaterThanOrEqualTo(50 + kOfferPeaceConsolidateGainsSoleGpWarBonus),
        );
      },
    );

    test(
      'stalled OW boosts offerPeace toward GP at war that does not own invadable minors',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(atWarWith: ['gp5']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 8,
            provincesToVictory: 24,
            invadableProvinceIdsSorted: ['oldWorld|p30'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-stalled-futile-gp-peace',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 100,
            ),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|p30',
                  regionId: 'oldWorld',
                  ownerId: 'minor1',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp4', displayName: 'P', isHuman: false),
            Player(id: 'gp5', displayName: 'Q', isHuman: false),
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
        final score = computeDiplomaticCandidateScores(
          DiplomaticCandidateScoringInput(
            candidates: const [
              DiplomaticOrder(
                type: DiplomaticOrderType.offerPeace,
                targetFactionId: 'gp5',
              ),
            ],
            nationId: 'gp4',
            game: game,
            snapshot: snap,
            config: config,
          ),
        ).single;
        expect(score, greaterThanOrEqualTo(50 + kOfferPeaceStalledFutileGpWarBonus));
      },
    );

    test(
      'below observer quota skips sated minor declare-war penalty at 9 OW provinces',
      () {
        const snapBelowQuota = AIWorldSnapshot(
          playerId: 'gp5',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 9,
            provincesToVictory: 22,
            invadableProvinceIdsSorted: ['oldWorld|minor1'],
            adjacentOwnerFactionIdsSorted: ['minor1'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        const snapAtQuota = AIWorldSnapshot(
          playerId: 'gp5',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 10,
            provincesToVictory: 21,
            invadableProvinceIdsSorted: ['oldWorld|minor1'],
            adjacentOwnerFactionIdsSorted: ['minor1'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-below-quota-sated',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 40,
            ),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|minor1',
                  regionId: 'oldWorld',
                  ownerId: 'minor1',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp5', displayName: 'P', isHuman: false),
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
        const order = DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'minor1',
        );
        final belowQuota = computeDiplomaticCandidateScores(
          DiplomaticCandidateScoringInput(
            candidates: const [order],
            nationId: 'gp5',
            game: game,
            snapshot: snapBelowQuota,
            config: config,
          ),
        ).single;
        final atQuota = computeDiplomaticCandidateScores(
          DiplomaticCandidateScoringInput(
            candidates: const [order],
            nationId: 'gp5',
            game: game,
            snapshot: snapAtQuota,
            config: config,
          ),
        ).single;
        expect(belowQuota, greaterThan(atQuota));
        expect(
          belowQuota - atQuota,
          greaterThanOrEqualTo(kDeclareWarSatedExpansionMinorPenalty),
        );
      },
    );
  });
}
