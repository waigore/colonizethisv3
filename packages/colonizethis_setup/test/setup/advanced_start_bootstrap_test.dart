import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'advanced_start_test_support.dart';

int _countUnitsOfType(Game game, String ownerId, String type) {
  return allUnitsFromWorld(
    game.worldState,
  ).where((u) => u.ownerId == ownerId && u.type == type).length;
}

int _countMilitaryRegiments(Game game, String ownerId) {
  return allUnitsFromWorld(
    game.worldState,
  ).where((u) => u.ownerId == ownerId && isMilitaryUnit(u.type)).length;
}

Fleet? _homeFleet(Game game, String playerId) {
  final id = homeFleetIdFor(playerId);
  for (final fleet in game.worldState.fleets) {
    if (fleet.id == id) return fleet;
  }
  return null;
}

void main() {
  group('applyAdvancedStartBootstrap', () {
    test('none leaves game unchanged', () {
      const player = Player(
        id: 'gp1',
        displayName: 'England',
        isHuman: true,
        treasury: 1000,
        workerPool: WorkerPool(peasants: 4),
      );
      final game = advancedStartGpGame(player: player);
      final config = GameSetupConfig.defaultConfig;

      final out = applyAdvancedStartBootstrap(game: game, config: config);

      expect(out.advancedStartType, isNull);
      expect(out.worldState.turnState.turnNumber, 0);
      expect(out.players.single.treasury, 1000);
      expect(out.players.single.workerPool.peasants, 4);
    });

    test(
      'turns50 applies economy, civilians, regiments, galleon, and diplomacy',
      () {
        const player = Player(
          id: 'gp1',
          displayName: 'England',
          isHuman: true,
          treasury: 1000,
          workerPool: WorkerPool(peasants: 4),
          capitalProvinceId: 'oldWorld|p1',
          capitalTile: CapitalTile(
            regionId: kRegionOldWorld,
            provinceId: 'p1',
            x: 1,
            y: 2,
          ),
        );
        final game = advancedStartGpGame(
          player: player,
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          oldWorldUnits: [
            Unit(
              id: 'gp1_explorer_1',
              type: kUnitTypeExplorer,
              ownerId: 'gp1',
              locationProvinceId: 'oldWorld|p1',
              status: UnitStatus.idle,
            ),
            Unit(
              id: 'gp1_peasant_levies_reg1',
              type: 'peasant_levies',
              ownerId: 'gp1',
              locationProvinceId: 'oldWorld|p1',
              status: UnitStatus.idle,
            ),
          ],
          fleets: [
            Fleet(
              id: homeFleetIdFor('gp1'),
              ownerId: 'gp1',
              regionId: kRegionOldWorld,
              inPortAtProvinceId: 'oldWorld|p1',
              ships: const [ShipInstance(id: 'ship_0', typeId: 'carrack')],
            ),
          ],
        );
        final config = GameSetupConfig(
          advancedStart: AdvancedStartType.turns50,
        );

        final out = applyAdvancedStartBootstrap(
          game: game,
          config: config,
          topologyOldWorld: const MapTopology(
            nodes: [
              TopologyNode(
                id: 'p1',
                regionId: kRegionOldWorld,
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: 's1',
                regionId: kRegionOldWorld,
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: [TopologyEdge(id1: 'p1', id2: 's1')],
          ),
          topologyNewWorld: const MapTopology(nodes: [], edges: []),
        );

        expect(out.advancedStartType, AdvancedStartType.turns50);
        expect(out.worldState.turnState.turnNumber, 50);
        expect(out.players.single.treasury, 20000);
        expect(out.players.single.workerPool.peasants, 16);
        expect(
          out.players.single.techUnlocked!.keys.where(
            (k) => out.players.single.techUnlocked![k] == true,
          ),
          hasLength(23),
        );
        expect(_countUnitsOfType(out, 'gp1', kUnitTypeExplorer), 3);
        expect(_countUnitsOfType(out, 'gp1', kUnitTypeSpy), 1);
        expect(_countMilitaryRegiments(out, 'gp1'), 6);
        expect(
          allUnitsFromWorld(
            out.worldState,
          ).where((u) => u.ownerId == 'gp1' && u.type == 'peasant_levies'),
          isEmpty,
        );
        final fleet = _homeFleet(out, 'gp1');
        expect(fleet, isNotNull);
        expect(fleet!.ships, hasLength(1));
        expect(fleet.ships.single.typeId, kAdvancedStartCargoShipTypeId);
        expect(
          getOverture(out, 'gp1', 'minor1')!.stage,
          OvertureStage.tradeConsulate,
        );
      },
    );

    test(
      'turns100 applies apprentices, civilians, 12 regiments, 6 galleons',
      () {
        const player = Player(
          id: 'gp1',
          displayName: 'England',
          isHuman: true,
          capitalProvinceId: 'oldWorld|p1',
          capitalTile: CapitalTile(
            regionId: kRegionOldWorld,
            provinceId: 'p1',
            x: 0,
            y: 0,
          ),
        );
        final game = advancedStartGpGame(
          player: player,
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
        );
        final config = GameSetupConfig(
          advancedStart: AdvancedStartType.turns100,
        );

        final out = applyAdvancedStartBootstrap(
          game: game,
          config: config,
          topologyOldWorld: const MapTopology(
            nodes: [
              TopologyNode(
                id: 'p1',
                regionId: kRegionOldWorld,
                type: TopologyNodeType.province,
              ),
            ],
            edges: const [],
          ),
          topologyNewWorld: const MapTopology(nodes: [], edges: []),
        );

        expect(out.advancedStartType, AdvancedStartType.turns100);
        expect(out.worldState.turnState.turnNumber, 100);
        expect(out.players.single.workerPool.apprentices, 4);
        expect(_countUnitsOfType(out, 'gp1', kUnitTypeRailBuilder), 1);
        expect(_countMilitaryRegiments(out, 'gp1'), 12);
        expect(_homeFleet(out, 'gp1')!.ships, hasLength(6));
        expect(getOverture(out, 'gp1', 'minor1')!.stage, OvertureStage.embassy);
      },
    );

    test('non-locked profile skips bootstrap', () {
      const player = Player(
        id: 'gp1',
        displayName: 'England',
        isHuman: true,
        treasury: 500,
      );
      final game = advancedStartGpGame(player: player);
      final config = GameSetupConfig(
        numProvincesOldWorld: 24,
        numProvincesNewWorld: 12,
        advancedStart: AdvancedStartType.turns50,
      );

      final out = applyAdvancedStartBootstrap(game: game, config: config);

      expect(out.advancedStartType, isNull);
      expect(out.worldState.turnState.turnNumber, 0);
      expect(out.players.single.treasury, 500);
    });
  });
}
