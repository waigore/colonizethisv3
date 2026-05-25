import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test(
    'multiFrontNonBlockerGpPeaceTargets with three GP wars and invadable OW',
    () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
          oldWorld: RegionData(
            provinces: [
              const Province(
                id: 'oldWorld|a',
                regionId: 'oldWorld',
                ownerId: 'gp4',
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
              const Province(
                id: 'oldWorld|d',
                regionId: 'oldWorld',
                ownerId: 'gp3',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp4', displayName: 'GP4', isHuman: false),
          Player(id: 'gp1', displayName: 'GP1', isHuman: false),
          Player(id: 'gp2', displayName: 'GP2', isHuman: false),
          Player(id: 'gp3', displayName: 'GP3', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp4',
            factionId2: 'gp1',
            state: RelationState.atWar,
            score: 30,
          ),
          DiplomacyRelation(
            factionId1: 'gp4',
            factionId2: 'gp2',
            state: RelationState.atWar,
            score: 30,
          ),
          DiplomacyRelation(
            factionId1: 'gp4',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['gp1', 'gp2', 'gp3']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 11,
          invadableProvinceIdsSorted: [
            'oldWorld|b',
            'oldWorld|c',
            'oldWorld|d',
          ],
        ),
        economy: EconomySummary(),
        relations: {},
      );

      final targets = multiFrontNonBlockerGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(targets.length, 2);
      expect(targets, isNot(contains('gp1')));
      expect(
        collectStalledGreatPowerPeaceTargets(game: game, snapshot: snapshot),
        containsAll(targets),
      );

      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp4': [
            for (final target in targets)
              DiplomaticOrder(
                type: DiplomaticOrderType.offerPeace,
                targetFactionId: target,
              ),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
      final gpWars = after.diplomacyRelations
          .where(
            (r) =>
                r.state == RelationState.atWar &&
                (r.factionId1 == 'gp4' || r.factionId2 == 'gp4') &&
                after.playerById(
                      r.factionId1 == 'gp4' ? r.factionId2 : r.factionId1,
                    ) !=
                    null,
          )
          .length;
      expect(gpWars, lessThanOrEqualTo(1));
    },
  );
}
