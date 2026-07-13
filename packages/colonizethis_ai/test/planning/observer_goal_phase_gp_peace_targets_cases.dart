// Case bodies for `observer_goal_phase_test.dart` (Refs #3997 Phase 8).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void registerObserverGoalPhaseGpPeaceTargetsCases() {
  group('expandPhaseGpPeaceTargets', () {
    test('peaces non-blocker GP when two GPs at war in expand phase', () {
      final game = Game(
        id: 'g-expand-peace',
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 50, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              const Province(
                id: 'oldWorld|a',
                regionId: 'oldWorld',
                ownerId: 'gp2',
              ),
              const Province(
                id: 'oldWorld|b',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
              const Province(
                id: 'oldWorld|c',
                regionId: 'oldWorld',
                ownerId: 'gp2',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: false),
          Player(id: 'gp2', displayName: 'P2', isHuman: false),
        ],
        minorNations: const [],
        tribes: const [],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: const ThreatSummary(atWarWith: ['gp2', 'gp3']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: ['oldWorld|a', 'oldWorld|c'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        expandPhaseGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
      );
      final gameWithGp3 = game.copyWith(
        players: [
          ...game.players,
          const Player(id: 'gp3', displayName: 'P3', isHuman: false),
        ],
      );
      expect(
        expandPhaseGpPeaceTargets(game: gameWithGp3, snapshot: snapshot),
        ['gp3'],
      );
    });

    test(
      'peaces every GP front when uninvaded minors remain below quota',
      () {
        final game = Game(
          id: 'g-expand-peace-all-gp-minors',
          worldState: WorldState(
            turnState: const TurnState(turnNumber: 50, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp4_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp4',
                  ),
                for (var i = 0; i < 11; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
                const Province(
                  id: 'oldWorld|minor1',
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
        );
        const snapshot = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(atWarWith: ['gp3']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 8,
            invadableProvinceIdsSorted: ['oldWorld|gp3_8'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          expandPhaseGpPeaceTargets(game: game, snapshot: snapshot),
          ['gp3'],
        );
      },
    );
  });

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

  group('collectStalledGreatPowerPeaceTargets phase gating', () {
    test('develop phase uses develop peace only, not expand ratchet', () {
      final game = Game(
        id: 'g-develop-collect',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 140),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 10; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              for (var i = 1; i <= 6; i++)
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
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp4',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['gp3']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 10),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.develop);
      expect(
        belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
      );
      expect(
        collectStalledGreatPowerPeaceTargets(game: game, snapshot: snapshot),
        developPhaseGpPeaceTargets(game: game, snapshot: snapshot).toSet(),
      );
    });

    test('expand phase still applies below-quota peer ratchet', () {
      final game = Game(
        id: 'g-expand-collect',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp6_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp6',
                ),
              const Province(
                id: 'oldWorld|minor1',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp5', displayName: 'P5', isHuman: false),
          Player(id: 'gp6', displayName: 'P6', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp5',
            factionId2: 'gp6',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp5',
        threats: ThreatSummary(atWarWith: ['gp6']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 8),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand);
      expect(
        collectStalledGreatPowerPeaceTargets(game: game, snapshot: snapshot),
        contains('gp6'),
      );
    });
  });

  group('developPhaseGpPeaceTargets', () {
    test('lists all at-war GPs in develop phase', () {
      final game = Game(
        id: 'g-develop-peace',
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 140, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: false),
          Player(id: 'gp2', displayName: 'P2', isHuman: false),
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
        ],
        minorNations: const [],
        tribes: const [],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: const ThreatSummary(atWarWith: ['gp2', 'gp3', 'minor1']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 11),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        developPhaseGpPeaceTargets(game: game, snapshot: snapshot),
        ['gp2', 'gp3'],
      );
    });
  });
}
