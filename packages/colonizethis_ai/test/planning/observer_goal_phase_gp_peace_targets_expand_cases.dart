// Expand-phase GP peace target cases (Refs #4310 Slice D topic-split).
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void registerObserverGoalPhaseGpPeaceTargetsExpandCases() {
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
}
