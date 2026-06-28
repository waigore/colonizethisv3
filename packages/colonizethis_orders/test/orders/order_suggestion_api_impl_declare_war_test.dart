import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('suggestDeclareWarOrders', () {
    test(
      'returns declareWar toward minor when establishOverture would win in suggestDiplomaticOrders',
      () {
        const api = DefaultOrderSuggestionAPI();
        const topology = MapTopology(nodes: [], edges: []);
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|m1',
                  regionId: 'oldWorld',
                  ownerId: 'minor1',
                ),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'gp1': {'oldWorld|m1|0|0': 'fullyVisible'},
            },
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                'oldWorld|m1': ['oldWorld|m1|0|0'],
              },
            },
          ),
          players: [
            const Player(id: 'gp1', displayName: 'A', isHuman: false).copyWith(
              treasury: 600,
              techUnlocked: const {kTechIdDiplomaticExpertise: true},
            ),
          ],
          minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
        );
        final view = buildPlayerView(game, topology, 'gp1');
        final general = api.suggestDiplomaticOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final declareOnly = api.suggestDeclareWarOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        expect(
          general.any(
            (o) =>
                o.targetFactionId == 'minor1' &&
                o.type == DiplomaticOrderType.establishOverture,
          ),
          isTrue,
        );
        expect(
          general.any(
            (o) =>
                o.targetFactionId == 'minor1' &&
                o.type == DiplomaticOrderType.declareWar,
          ),
          isFalse,
        );
        expect(
          declareOnly.any(
            (o) =>
                o.targetFactionId == 'minor1' &&
                o.type == DiplomaticOrderType.declareWar,
          ),
          isTrue,
        );
        expect(
          declareOnly.every((o) => o.type == DiplomaticOrderType.declareWar),
          isTrue,
        );
      },
    );
  });
}
