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
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
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
          conquest: ConquestSummary(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
            provincesToVictory: 24,
          ),
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

    // EXPAND companion to the COLONIAL invadable-bonus case above. Pins
    // `SPEC/ai/ai-architecture.md` § Observer goal phases (Full AI) EXPAND
    // rule: "Suppress: NW declareWar/establishOverture..." while
    // `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp` (Refs
    // #2509). Same game/snapshot shape, but below-quota OW puts the GP in
    // EXPAND so the establishOverture suppression branch in
    // `computeDiplomaticCandidateScores` must collapse the score to 0 instead
    // of returning the COLONIAL invadable-owner bonus.
    test(
      'EXPAND below quota suppresses establishOverture toward tribe owning NW',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
            provincesToVictory: 26,
          ),
          colonial: ColonialSummary(
            invadableNewWorldProvinceIdsSorted: ['newWorld|nw1'],
          ),
          economy: EconomySummary(),
          relations: {},
        );
        final game = Game(
          id: 'g-expand-overture-suppress',
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
        expect(score, 0);
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
  });
}
