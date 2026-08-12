// Stalled-collect and develop-phase GP peace cases (Refs #4310 Slice D).
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void registerObserverGoalPhaseGpPeaceTargetsStalledDevelopCases() {
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
