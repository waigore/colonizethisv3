import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';


void main() {
  group('computeDiplomaticCandidateScores suppression', () {
    test(
      'colonial-adjacent tribe declareWar is not suppressed when only OW-adjacent list is empty',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            provincesToVictory: 24,
            adjacentOwnerFactionIdsSorted: [],
          ),
          colonial: ColonialSummary(
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-colonial-tribe',
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
          ],
          tribes: const [
            Tribe(id: 'tribe1', displayName: 'T1'),
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
              targetFactionId: 'tribe1',
            ),
          ],
          nationId: 'gp1',
          game: game,
          snapshot: snap,
          config: config,
        ).single;
        expect(score, greaterThan(0));
        expect(score, greaterThanOrEqualTo(kDeclareWarColonialAdjacentTribeBonus));
      },
    );

    test(
      'stalled OW expansion prioritizes adjacent minor over tribe without NW provinces',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 7,
            provincesToVictory: 24,
            invadableProvinceIdsSorted: ['oldWorld|minor1'],
            adjacentOwnerFactionIdsSorted: ['minor1'],
          ),
          colonial: ColonialSummary(
            invadableNewWorldProvinceIdsSorted: ['newWorld|nw1'],
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-stalled-ow-minor',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 1,
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
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: 'newWorld|nw1',
                  regionId: 'newWorld',
                  ownerId: 'tribe1',
                ),
              ],
            ),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'M1'),
          ],
          tribes: const [
            Tribe(id: 'tribe1', displayName: 'T1'),
          ],
        );
        const config = AIConfig(
          leaderId: 'henry',
          personalityId: 'henry',
          hiddenAgendaId: 'peacemaker',
        );
        final scores = computeDiplomaticCandidateScores(
          candidates: const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'tribe1',
            ),
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'minor1',
            ),
          ],
          nationId: 'gp1',
          game: game,
          snapshot: snap,
          config: config,
        );
        expect(scores[1], greaterThan(scores[0]));
      },
    );

    test(
      'stalled OW expansion prioritizes adjacent minor even when tribe owns sea-reachable NW',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 7,
            provincesToVictory: 24,
            invadableProvinceIdsSorted: ['oldWorld|minor1'],
            adjacentOwnerFactionIdsSorted: ['minor1'],
          ),
          colonial: ColonialSummary(
            newWorldProvincesOwned: 0,
            invadableNewWorldProvinceIdsSorted: ['newWorld|nw1'],
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-colonial-nw-tribe',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 1,
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
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: 'newWorld|nw1',
                  regionId: 'newWorld',
                  ownerId: 'tribe1',
                ),
              ],
            ),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'M1'),
          ],
          tribes: const [
            Tribe(id: 'tribe1', displayName: 'T1'),
          ],
        );
        const config = AIConfig(
          leaderId: 'henry',
          personalityId: 'henry',
          hiddenAgendaId: 'merchant',
        );
        final scores = computeDiplomaticCandidateScores(
          candidates: const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'tribe1',
            ),
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'minor1',
            ),
          ],
          nationId: 'gp1',
          game: game,
          snapshot: snap,
          config: config,
        );
        expect(scores[0], 0);
        expect(scores[1], greaterThan(0));
      },
    );

    test(
      'stalled OW expansion scores weaker distant minor when invadable border is GP-owned',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 7,
            provincesToVictory: 24,
            invadableProvinceIdsSorted: ['oldWorld|p30'],
            adjacentOwnerFactionIdsSorted: ['gp3'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-stalled-weaker-distant-minor',
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
                  ownerId: 'gp3',
                ),
                Province(
                  id: 'oldWorld|m1',
                  regionId: 'oldWorld',
                  ownerId: 'minor2',
                ),
                Province(
                  id: 'oldWorld|m2',
                  regionId: 'oldWorld',
                  ownerId: 'minor2',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp4', displayName: 'P', isHuman: false),
            Player(id: 'gp3', displayName: 'Q', isHuman: false),
          ],
          minorNations: const [
            MinorNation(id: 'minor2', displayName: 'M2'),
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
              targetFactionId: 'minor2',
            ),
          ],
          nationId: 'gp4',
          game: game,
          snapshot: snap,
          config: config,
        ).single;
        expect(score, greaterThan(0));
      },
    );

    test(
      'stalled OW expansion scores distant invadable minor when only adjacent owners are GPs',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 7,
            provincesToVictory: 24,
            invadableProvinceIdsSorted: ['oldWorld|minor1'],
            adjacentOwnerFactionIdsSorted: ['gp2'],
          ),
          colonial: ColonialSummary(
            invadableNewWorldProvinceIdsSorted: ['newWorld|nw1'],
          ),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-colonial-stalled-distant',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 1,
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
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: 'newWorld|nw1',
                  regionId: 'newWorld',
                  ownerId: 'tribe1',
                ),
              ],
            ),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'M1'),
          ],
          tribes: const [
            Tribe(id: 'tribe1', displayName: 'T1'),
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
              targetFactionId: 'minor1',
            ),
          ],
          nationId: 'gp1',
          game: game,
          snapshot: snap,
          config: config,
        ).single;
        expect(score, greaterThan(0));
      },
    );

    test(
      'stalled OW expansion keeps adjacent minor declareWar score under colonial pressure',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 7,
            provincesToVictory: 24,
            invadableProvinceIdsSorted: ['oldWorld|minor1'],
            adjacentOwnerFactionIdsSorted: ['minor1'],
          ),
          colonial: ColonialSummary(
            newWorldProvincesOwned: 0,
            invadableNewWorldProvinceIdsSorted: ['newWorld|nw1'],
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-colonial-stalled-ow',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 1,
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
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: 'newWorld|nw1',
                  regionId: 'newWorld',
                  ownerId: 'tribe1',
                ),
              ],
            ),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'M1'),
          ],
          tribes: const [
            Tribe(id: 'tribe1', displayName: 'T1'),
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
              targetFactionId: 'minor1',
            ),
          ],
          nationId: 'gp1',
          game: game,
          snapshot: snap,
          config: config,
        ).single;
        expect(score, greaterThan(0));
        expect(
          score,
          greaterThanOrEqualTo(
            kDeclareWarStalledExpansionMinorBonus +
                kDeclareWarAdjacentMinorBonusWhenFarFromVictory,
          ),
        );
      },
    );

    test(
      'establishOverture toward tribe owning sea-reachable NW gets invadable bonus',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(provincesToVictory: 24),
          colonial: ColonialSummary(
            invadableNewWorldProvinceIdsSorted: ['newWorld|nw1'],
          ),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-colonial-overture',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: const RegionData(),
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: 'newWorld|nw1',
                  regionId: 'newWorld',
                  ownerId: 'tribe1',
                ),
              ],
            ),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
          ],
          tribes: const [
            Tribe(id: 'tribe1', displayName: 'T1'),
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
              type: DiplomaticOrderType.establishOverture,
              targetFactionId: 'tribe1',
            ),
          ],
          nationId: 'gp1',
          game: game,
          snapshot: snap,
          config: config,
        ).single;
        expect(score, greaterThanOrEqualTo(kEstablishOvertureColonialInvadableOwnerBonus));
      },
    );

    test(
      'stalled OW suppresses tribe declareWar when invadable OW is GP-owned',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 7,
            provincesToVictory: 24,
            invadableProvinceIdsSorted: ['oldWorld|p30'],
            adjacentOwnerFactionIdsSorted: ['gp3'],
          ),
          colonial: ColonialSummary(
            invadableNewWorldProvinceIdsSorted: ['newWorld|nw1'],
          ),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-stalled-gp-blocker-tribe',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 40,
            ),
            oldWorld: const RegionData(
              provinces: [
                Province(
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
              targetFactionId: 'tribe1',
            ),
          ],
          nationId: 'gp4',
          game: game,
          snapshot: snap,
          config: config,
        ).single;
        expect(score, 0);
      },
    );

    test(
      'stalled OW scores declareWar on adjacent GP invadable blocker',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 7,
            provincesToVictory: 24,
            invadableProvinceIdsSorted: ['oldWorld|p30'],
            adjacentOwnerFactionIdsSorted: ['gp3'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-stalled-gp-blocker-declare',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 40,
            ),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|p30',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
                Province(
                  id: 'oldWorld|p31',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
                Province(
                  id: 'oldWorld|p32',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
                Province(
                  id: 'oldWorld|p33',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
                Province(
                  id: 'oldWorld|p34',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
                Province(
                  id: 'oldWorld|p35',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
                Province(
                  id: 'oldWorld|p36',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
                Province(
                  id: 'oldWorld|p37',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
                Province(
                  id: 'oldWorld|p38',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
                Province(
                  id: 'oldWorld|p39',
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
        expect(score, greaterThan(0));
        expect(score, greaterThanOrEqualTo(kDeclareWarStalledInvadableGpBlockerBonus));
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
      'stalled OW boosts offerPeace toward GP at war that does not own invadable minors',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(atWarWith: ['gp5']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 7,
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
