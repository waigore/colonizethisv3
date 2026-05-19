import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';



void main() {
  group('computeDiplomaticCandidateScores suppression (part 2)', () {
    test(
      'suppresses mutual plateau declareWar on peer within one OW province',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 8,
            provincesToVictory: 10,
            invadableProvinceIdsSorted: ['oldWorld|p30'],
            adjacentOwnerFactionIdsSorted: ['gp3'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-mutual-plateau-suppress',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 40,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp4_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp4',
                  ),
                const Province(
                  id: 'oldWorld|p30',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp3', displayName: 'C', isHuman: false),
            Player(id: 'gp4', displayName: 'D', isHuman: false),
          ],
        );
        final score = computeDiplomaticCandidateScores(
          candidates: const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp3',
            ),
          ],
          nationId: 'gp4',
          game: game,
          snapshot: snap,
          config: const AIConfig(
            leaderId: 'henry',
            personalityId: 'henry',
            hiddenAgendaId: 'merchant',
          ),
          primaryGoal: StrategicGoal.conquer,
        ).single;
        expect(score, 0);
      },
    );

    test(
      'stalledGpBlockerDeclareWarTarget returns GP-only invadable blocker',
      () {
        final game = Game(
          id: 'g-stalled-gp-blocker-declare',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 60,
            ),
            oldWorld: RegionData(
              provinces: [
                const Province(
                  id: 'oldWorld|p30',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
                for (final id in ['p36', 'p37', 'p38', 'p39'])
                  Province(
                    id: 'oldWorld|$id',
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
        );
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 4,
            invadableProvinceIdsSorted: ['oldWorld|p30'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          stalledGpBlockerDeclareWarTarget(game: game, snapshot: snap),
          'gp3',
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
        ).single;
        expect(score, 0);
      },
    );

    test(
      'suppresses declareWar on below-quota GP in GP war when attacker meets quota',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 12,
            provincesToVictory: 19,
            invadableProvinceIdsSorted: ['oldWorld|p30'],
            adjacentOwnerFactionIdsSorted: ['gp3'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-quota-dogpile',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 50,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
                for (var i = 0; i < 12; i++)
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
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp3',
              state: RelationState.atWar,
              score: 0,
            ),
          ],
        );
        const config = AIConfig(
          leaderId: 'henry',
          personalityId: 'henry',
          hiddenAgendaId: 'merchant',
        );
        final score = computeDiplomaticCandidateScores(
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
        ).single;
        expect(score, 0);
      },
    );

    test(
      'suppresses early declareWar on below-quota GP already in one GP war',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 11,
            provincesToVictory: 20,
            invadableProvinceIdsSorted: ['oldWorld|p30'],
            adjacentOwnerFactionIdsSorted: ['gp3'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-second-attacker',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 2,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
                for (var i = 0; i < 11; i++)
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
          sameTurnPriorDiplomaticOrders: Orders(
            diplomaticOrdersByPlayerId: {
              'gp1': [
                const DiplomaticOrder(
                  type: DiplomaticOrderType.declareWar,
                  targetFactionId: 'gp3',
                ),
              ],
            },
          ),
        ).single;
        expect(score, 0);
      },
    );

    test(
      'suppresses new declareWar on below-quota GP with zero regiments',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 11,
            provincesToVictory: 20,
            invadableProvinceIdsSorted: ['oldWorld|p30'],
            adjacentOwnerFactionIdsSorted: ['gp3'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-zero-regiment-victim',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 2,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
                for (var i = 0; i < 11; i++)
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
        ).single;
        expect(score, 0);
      },
    );

    test(
      'suppresses new declareWar on below-quota adjacent GP when attacker meets quota',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 11,
            provincesToVictory: 20,
            invadableProvinceIdsSorted: ['oldWorld|p30'],
            adjacentOwnerFactionIdsSorted: ['gp3'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-suppress-below-quota-victim',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 12,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
                for (var i = 0; i < 11; i++)
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
        ).single;
        expect(score, 0);
      },
    );

    test(
      'suppresses declareWar on critically weak adjacent GP when attacker leads by 4+',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 11,
            provincesToVictory: 20,
            invadableProvinceIdsSorted: ['oldWorld|p30'],
            adjacentOwnerFactionIdsSorted: ['gp3'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-suppress-weak-gp-declare',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 40,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 4; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
                for (var i = 0; i < 11; i++)
                  Province(
                    id: 'oldWorld|gp4_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp4',
                  ),
                const Province(
                  id: 'oldWorld|p30',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp3', displayName: 'C', isHuman: false),
            Player(id: 'gp4', displayName: 'D', isHuman: false),
          ],
        );
        const config = AIConfig(
          leaderId: 'henry',
          personalityId: 'henry',
          hiddenAgendaId: 'merchant',
        );
        final score = computeDiplomaticCandidateScores(
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
        ).single;
        expect(score, 0);
      },
    );

    test(
      'offerPeace boosts quota-met futile below-quota GP victim',
      () {
        final game = Game(
          id: 'g-offer-peace-quota-victim',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 50,
            ),
            oldWorld: RegionData(
              provinces: [
                for (var i = 1; i <= 12; i++)
                  Province(
                    id: 'oldWorld|gp4_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp4',
                  ),
                for (var i = 1; i <= 8; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
                const Province(
                  id: 'oldWorld|inv1',
                  regionId: 'oldWorld',
                  ownerId: 'minor1',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp4', displayName: 'P4', isHuman: false),
            Player(id: 'gp3', displayName: 'P3', isHuman: false),
          ],
          minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
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
            provincesToVictory: 20,
            invadableProvinceIdsSorted: ['oldWorld|inv1'],
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
        ).single;
        expect(score, greaterThanOrEqualTo(50 + kOfferPeaceStalledFutileGpWarBonus));
      },
    );

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
          candidates: const [order],
          nationId: 'gp5',
          game: game,
          snapshot: snapBelowQuota,
          config: config,
        ).single;
        final atQuota = computeDiplomaticCandidateScores(
          candidates: const [order],
          nationId: 'gp5',
          game: game,
          snapshot: snapAtQuota,
          config: config,
        ).single;
        expect(belowQuota, greaterThan(atQuota));
        expect(
          belowQuota - atQuota,
          greaterThanOrEqualTo(kDeclareWarSatedExpansionMinorPenalty),
        );
      },
    );

    test(
      'stalled GP at war suppresses declareWar on a second Great Power',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp6',
          threats: ThreatSummary(atWarWith: ['gp3']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 7,
            provincesToVictory: 24,
            invadableProvinceIdsSorted: ['oldWorld|p1'],
            adjacentOwnerFactionIdsSorted: ['gp5'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-stalled-second-gp-front',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 20,
            ),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp3', displayName: 'A', isHuman: false),
            Player(id: 'gp5', displayName: 'B', isHuman: false),
            Player(id: 'gp6', displayName: 'C', isHuman: false),
          ],
        );
        const config = AIConfig(
          leaderId: 'henry',
          personalityId: 'henry',
          hiddenAgendaId: 'merchant',
        );
        final score = computeDiplomaticCandidateScores(
          candidates: const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp5',
            ),
          ],
          nationId: 'gp6',
          game: game,
          snapshot: snap,
          config: config,
        ).single;
        expect(score, 0);
      },
    );
  });
}
