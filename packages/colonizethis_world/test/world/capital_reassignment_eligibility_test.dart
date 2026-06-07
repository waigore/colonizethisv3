import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('evaluateCapitalReassignmentEligibility', () {
    test(
      'returns deterministic candidate when owner has provinces in region',
      () {
        final game = Game(
          id: 'g-cap-eligible',
          worldState: const WorldState(
            turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|P2',
                  regionId: 'oldWorld',
                  ownerId: 'p1',
                ),
                Province(
                  id: 'oldWorld|P1',
                  regionId: 'oldWorld',
                  ownerId: 'p1',
                ),
              ],
            ),
            newWorld: RegionData(),
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );

        final eligibility = evaluateCapitalReassignmentEligibility(
          state: game,
          playerId: 'p1',
          regionId: 'oldWorld',
          regionTopology: const MapTopology(),
        );

        expect(eligibility.eligible, isTrue);
        expect(eligibility.reasonCode, 'eligible');
        expect(eligibility.candidateProvinceId, 'oldWorld|P1');
      },
    );

    test('reports ineligible when owner has no provinces in region', () {
      final game = Game(
        id: 'g-cap-ineligible',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p2'),
            ],
          ),
          newWorld: RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final eligibility = evaluateCapitalReassignmentEligibility(
        state: game,
        playerId: 'p1',
        regionId: 'oldWorld',
        regionTopology: const MapTopology(),
      );

      expect(eligibility.eligible, isFalse);
      expect(eligibility.reasonCode, 'no_owned_provinces_in_region');
      expect(eligibility.candidateProvinceId, isNull);
    });
  });
}
