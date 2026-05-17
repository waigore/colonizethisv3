import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('computeDiplomaticCandidateScores', () {
    test('declareWar score exceeds establishOverture for same hostile target', () {
      final game = Game(
        id: 'g-diplo-score-1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
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
                ownerId: 'gp1',
              ),
              Province(
                id: 'oldWorld|p3',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
              Province(
                id: 'oldWorld|p4',
                regionId: 'oldWorld',
                ownerId: 'gp2',
              ),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|p1',
              ),
              Unit(
                id: 'u2',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|p2',
              ),
              Unit(
                id: 'u3',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|p3',
              ),
              Unit(
                id: 'u4',
                type: 'grenadiers',
                ownerId: 'gp2',
                locationProvinceId: 'oldWorld|p4',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 20,
            level: RelationLevel.hostile,
            state: RelationState.atPeace,
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, 'gp1');
      final snapshot = AIWorldSnapshot.fromPlayerView(view);
      const config = AIConfig(
        leaderId: 'napoleon',
        personalityId: 'napoleon',
        hiddenAgendaId: 'warmonger',
      );
      final scores = computeDiplomaticCandidateScores(
        candidates: const [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'gp2',
          ),
          DiplomaticOrder(
            type: DiplomaticOrderType.establishOverture,
            targetFactionId: 'gp2',
          ),
        ],
        nationId: 'gp1',
        game: game,
        snapshot: snapshot,
        config: config,
      );
      expect(scores.length, 2);
      expect(scores[0], greaterThan(scores[1]));
    });

    test('offer peace candidate scores lower when war desire is higher', () {
      Game gameForWarDesire({
        required int gp2ProvinceCount,
        required int gp2Regiments,
      }) {
        final provinces = <Province>[
          const Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            ownerId: 'gp1',
          ),
        ];
        var i = 0;
        for (; i < gp2ProvinceCount; i++) {
          provinces.add(
            Province(
              id: 'oldWorld|g2_$i',
              regionId: 'oldWorld',
              ownerId: 'gp2',
            ),
          );
        }
        final units = <Unit>[
          Unit(
            id: 'a1',
            type: 'grenadiers',
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|p1',
          ),
          Unit(
            id: 'a2',
            type: 'grenadiers',
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|p1',
          ),
        ];
        for (var r = 0; r < gp2Regiments; r++) {
          units.add(
            Unit(
              id: 'b$r',
              type: 'grenadiers',
              ownerId: 'gp2',
              locationProvinceId: 'oldWorld|g2_0',
            ),
          );
        }
        return Game(
          id: 'g-peace-$gp2ProvinceCount-$gp2Regiments',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: RegionData(provinces: provinces, units: units),
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
              score: 25,
              level: RelationLevel.hostile,
              state: RelationState.atWar,
            ),
          ],
        );
      }

      final highDesireGame = gameForWarDesire(gp2ProvinceCount: 1, gp2Regiments: 1);
      final lowDesireGame =
          gameForWarDesire(gp2ProvinceCount: 3, gp2Regiments: 4);
      expect(
        computeWarDesireScore(
          game: highDesireGame,
          nationId: 'gp1',
          targetFactionId: 'gp2',
          relationScore: 25,
        ),
        greaterThan(
          computeWarDesireScore(
            game: lowDesireGame,
            nationId: 'gp1',
            targetFactionId: 'gp2',
            relationScore: 25,
          ),
        ),
      );
      const topology = MapTopology(nodes: [], edges: []);
      final viewHi = buildPlayerView(highDesireGame, topology, 'gp1');
      final viewLo = buildPlayerView(lowDesireGame, topology, 'gp1');
      final snapHi = AIWorldSnapshot.fromPlayerView(viewHi);
      final snapLo = AIWorldSnapshot.fromPlayerView(viewLo);
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final peaceHi = computeDiplomaticCandidateScores(
        candidates: const [
          DiplomaticOrder(
            type: DiplomaticOrderType.offerPeace,
            targetFactionId: 'gp2',
          ),
        ],
        nationId: 'gp1',
        game: highDesireGame,
        snapshot: snapHi,
        config: config,
      ).single;
      final peaceLo = computeDiplomaticCandidateScores(
        candidates: const [
          DiplomaticOrder(
            type: DiplomaticOrderType.offerPeace,
            targetFactionId: 'gp2',
          ),
        ],
        nationId: 'gp1',
        game: lowDesireGame,
        snapshot: snapLo,
        config: config,
      ).single;
      expect(peaceLo, greaterThan(peaceHi));
    });

    test('declareWar toward weak-neighbor GP gets GP targeting bonus', () {
      final game = Game(
        id: 'g-gp-war-bonus',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
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
            score: 25,
            level: RelationLevel.hostile,
            state: RelationState.atPeace,
          ),
        ],
      );
      const config = AIConfig(
        leaderId: 'napoleon',
        personalityId: 'napoleon',
        hiddenAgendaId: 'warmonger',
      );
      const candidate = [
        DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'gp2',
        ),
      ];
      final withWeakGp = computeDiplomaticCandidateScores(
        candidates: candidate,
        nationId: 'gp1',
        game: game,
        snapshot: const AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(weakNeighbors: ['gp2']),
          conquest: ConquestSummary(provincesToVictory: 10),
          economy: EconomySummary(),
          relations: {},
        ),
        config: config,
        primaryGoal: StrategicGoal.conquer,
      ).single;
      final withoutWeakGp = computeDiplomaticCandidateScores(
        candidates: candidate,
        nationId: 'gp1',
        game: game,
        snapshot: const AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(provincesToVictory: 10),
          economy: EconomySummary(),
          relations: {},
        ),
        config: config,
        primaryGoal: StrategicGoal.conquer,
      ).single;
      expect(withWeakGp, greaterThan(withoutWeakGp));
      expect(
        withWeakGp - withoutWeakGp,
        greaterThanOrEqualTo(kDeclareWarGpWeakNeighborBonus),
      );
    });

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
          candidates: candidate,
          nationId: 'gp1',
          game: game,
          snapshot: behindPaceSnapshot,
          config: config,
        ).single;
        final nearVictoryScore = computeDiplomaticCandidateScores(
          candidates: candidate,
          nationId: 'gp1',
          game: game,
          snapshot: nearVictorySnapshot,
          config: config,
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
        ).single;
        final distantScore = computeDiplomaticCandidateScores(
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
        ).single;
        expect(adjacentScore, greaterThan(distantScore));
        expect(
          adjacentScore - distantScore,
          greaterThanOrEqualTo(kDeclareWarAdjacentOwnerBonus),
        );
        expect(distantScore, kDeclareWarNonAdjacentSuppressedScore);
      },
    );

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
        final gpScore = computeDiplomaticCandidateScores(
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
        ).single;
        expect(gpScore, kDeclareWarNonAdjacentSuppressedScore);
      },
    );

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
      'tribe owning sea-reachable NW outscores adjacent OW minor under colonial pressure',
      () {
        const snap = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 9,
            provincesToVictory: 22,
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
        expect(scores[0], greaterThan(scores[1]));
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
  });
}
