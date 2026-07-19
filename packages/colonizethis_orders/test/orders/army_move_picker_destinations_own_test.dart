// Ported from colonizethis_logic (Refs #4090 Slice D).
// Split from army_move_picker_destinations_test for
// repo.domain_package_test_file_size (≤400 physical lines).
// Table-driven for repo.orders_test_prefer_scenario_tables (Refs #3949).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'support/army_move_picker_destinations_fixtures.dart';
import 'support/scenario_runner.dart';

void main() {
  const ow = kArmyMovePickerOw;
  const nw = kArmyMovePickerNw;

  runLabeledScenarioGroup('armyMovePickerDestinationsOwn', [
    rs('picker includes adjacent own-province move (no declare war)', () {
      const p1 = 'gp1';
      const p2 = 'gp2';
      const loc1 = '$ow|P1';
      const loc2 = '$ow|P2';
      final army = armyMovePickerFieldArmy(ow, p1, 'P1', 'u1');
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: loc1, regionId: ow, ownerId: p1),
              Province(id: loc2, regionId: ow, ownerId: p1),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: p1,
                locationProvinceId: loc1,
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [army],
          playerVisibilityByTile: {
            p1: armyMovePickerVis([(loc1, '$ow|P1|0|0'), (loc2, '$ow|P2|0|0')]),
          },
          tileKeysByRegionAndProvince: {
            ow: {
              loc1: ['$ow|P1|0|0'],
              loc2: ['$ow|P2|0|0'],
            },
          },
        ),
        players: const [
          Player(id: p1, displayName: 'A', isHuman: true),
          Player(id: p2, displayName: 'B', isHuman: true),
        ],
      );
      final list = armyMovePickerDestinations(
        game: game,
        topology: armyMovePickerAdjacencyOw,
        playerId: p1,
        army: army,
        currentOrders: const Orders(),
      );
      expect(list.map((e) => e.fullProvinceId), contains(loc2));
      expect(list.every((e) => !e.requiresDeclareWarOnConfirm), isTrue);
    }),
    rs('picker includes cross-region own province (different landmass)', () {
      const p1 = 'gp1';
      const locOw = '$ow|P1';
      const locNw = '$nw|N1';
      final army = armyMovePickerFieldArmy(ow, p1, 'P1', 'u1');
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [Province(id: locOw, regionId: ow, ownerId: p1)],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: p1,
                locationProvinceId: locOw,
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: [
              Province(
                id: locNw,
                regionId: nw,
                ownerId: p1,
                displayName: 'Colony',
              ),
            ],
          ),
          armies: [army],
          playerVisibilityByTile: {
            p1: armyMovePickerVis([
              (locOw, '$ow|P1|0|0'),
              (locNw, '$nw|N1|0|0'),
            ]),
          },
          tileKeysByRegionAndProvince: {
            ow: {
              locOw: ['$ow|P1|0|0'],
            },
            nw: {
              locNw: ['$nw|N1|0|0'],
            },
          },
        ),
        players: const [Player(id: p1, displayName: 'A', isHuman: true)],
      );
      final list = armyMovePickerDestinations(
        game: game,
        topology: const MapTopology(),
        playerId: p1,
        army: army,
        currentOrders: const Orders(),
      );
      expect(list.map((e) => e.fullProvinceId), contains(locNw));
      final nwEntry = list.firstWhere((e) => e.fullProvinceId == locNw);
      expect(nwEntry.isPlayerOwned, isTrue);
      expect(nwEntry.requiresDeclareWarOnConfirm, isFalse);
    }),
  ], runRunnableScenario);
}
