import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  test(
    'addStartingMilitaryAndNaval merges home fleets with pre-seeded fleets (Refs #2394)',
    () {
      final shipTypeId = ShipEconomyCatalog.carrack.shipTypeId;

      final gp1Capital = const CapitalTile(
        regionId: kRegionOldWorld,
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      );
      final gp2Capital = const CapitalTile(
        regionId: kRegionOldWorld,
        provinceId: 'oldWorld|p2',
        x: 0,
        y: 0,
      );

      final game = Game(
        id: 't',
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'z_unrelated_fleet_first',
              ownerId: 'gp1',
              regionId: kRegionOldWorld,
              seaZoneId: 'oldWorld|sea1',
              ships: const [],
            ),
            Fleet(
              id: 'fleet_gp1',
              ownerId: 'gp1',
              regionId: kRegionOldWorld,
              inPortAtProvinceId: 'oldWorld|p1',
              ships: [
                ShipInstance(id: 'ship_1', typeId: shipTypeId),
              ],
            ),
          ],
          nextShipInstanceSeq: 1,
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'England',
            isHuman: true,
            capitalProvinceId: 'oldWorld|p1',
            capitalTile: gp1Capital,
          ),
          Player(
            id: 'gp2',
            displayName: 'France',
            isHuman: false,
            capitalProvinceId: 'oldWorld|p2',
            capitalTile: gp2Capital,
          ),
        ],
      );

      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england'],
        startingResources: const StartingResourcesConfig(
          initialMilitaryRegiments: 0,
          initialNavalShips: 2,
        ),
      );

      final out = addStartingMilitaryAndNaval(
        game: game,
        config: config,
        topologyOldWorld: const MapTopology(nodes: [], edges: []),
      );

      final fleets = out.worldState.fleets;
      expect(fleets.length, 3);

      final gp1 = fleets.firstWhere((f) => f.id == 'fleet_gp1');
      expect(gp1.ships.length, 3);
      expect(gp1.ships.first.id, 'ship_1');
      expect(gp1.ships[1].id, 'ship_2');
      expect(gp1.ships[2].id, 'ship_3');

      final gp2 = fleets.firstWhere((f) => f.id == 'fleet_gp2');
      expect(gp2.inPortAtProvinceId, 'oldWorld|p2');
      expect(gp2.ships.length, 2);
      expect(gp2.ships.map((s) => s.id).toList(), ['ship_4', 'ship_5']);

      expect(out.worldState.nextShipInstanceSeq, 6);
    },
  );
}
