import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test(
    'stalledExpansionDistractionPeaceTargets peace tribes not focus minor',
    () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: RegionData(
            provinces: [
              const Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
              const Province(
                id: 'oldWorld|p2',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
              const Province(
                id: 'oldWorld|p3',
                regionId: 'oldWorld',
                ownerId: 'tribe1',
              ),
            ],
            units: [],
          ),
          newWorld: const RegionData(provinces: [], units: []),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: false,
            leaderKey: 'victoria',
          ),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe')],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            state: RelationState.atWar,
            score: 30,
          ),
          const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'tribe1',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(atWarWith: ['minor1', 'tribe1']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|p2'],
        ),
        economy: EconomySummary(),
        relations: {},
      );

      final targets = stalledExpansionDistractionPeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, ['tribe1']);
    },
  );
}
