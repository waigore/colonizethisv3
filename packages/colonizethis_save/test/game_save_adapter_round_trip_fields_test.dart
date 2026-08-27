import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart';

import 'support/game_save_adapter_test_harness.dart';

/// Local work-target id — avoid `colonizethis_logic` barrel from save tests.
/// Refs #4664.
const String _kWorkTargetBuildImprovement = 'build_improvement';

void main() {
  final harness = GameSaveAdapterHiveHarness(
    hivePath: './.dart_tool/test_hive_save_fields',
    boxName: 'games_fields',
  );

  setUpAll(harness.open);
  tearDownAll(harness.close);
  setUp(harness.reset);

  group('GameSaveAdapter field round-trips', () {
    test('save/load round-trip includes tile state, ports, and capital', () {
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 2)
          .setRoadLevel('oldWorld|p1|0|0', 1);
      final game =
          minimalSaveGame(
            id: 'withCapital',
            turnNumber: 1,
            players: [
              Player(
                id: 'pl1',
                displayName: 'Spain',
                isHuman: true,
                capitalProvinceId: 'oldWorld|p1',
                capitalTile: const CapitalTile(
                  regionId: 'oldWorld',
                  provinceId: 'oldWorld|p1',
                  x: 0,
                  y: 0,
                ),
              ),
            ],
          ).copyWith(
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 1,
              ),
              oldWorld: RegionData(
                provinces: [
                  Province(
                    id: 'oldWorld|p1',
                    regionId: 'oldWorld',
                    ownerId: 'pl1',
                  ),
                ],
              ),
              newWorld: const RegionData(),
              tileState: tileState,
              portsByProvinceSeaboard: const {'p1|sea1': 'oldWorld|p1|0|0'},
            ),
          );
      harness.adapter.save(harness.box, game);
      final loaded = harness.adapter.load(harness.box, 'withCapital')!;
      expect(
        loaded.worldState.tileState.improvementLevel('oldWorld|p1|0|0'),
        2,
      );
      expect(loaded.worldState.tileState.roadLevel('oldWorld|p1|0|0'), 1);
      expect(
        loaded.worldState.portsByProvinceSeaboard['p1|sea1'],
        'oldWorld|p1|0|0',
      );
      expect(loaded.players.single.capitalProvinceId, 'oldWorld|p1');
      expect(loaded.players.single.capitalTile?.regionId, 'oldWorld');
      expect(loaded.players.single.capitalTile?.x, 0);
      expect(loaded.players.single.capitalTile?.y, 0);
    });

    test('save/load preserves civilian origin/assigned tile fields', () {
      final unit = Unit(
        id: 'civ1',
        type: kUnitTypeBuilder,
        ownerId: 'pl1',
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|1|0',
        originTileKey: 'oldWorld|p1|0|0',
        assignedTileKey: 'oldWorld|p1|1|0',
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: _kWorkTargetBuildImprovement,
          tileKey: 'oldWorld|p1|1|0',
          totalTurns: 2,
          remainingTurns: 1,
        ),
      );
      final game =
          minimalSaveGame(
            id: 'withCivilianAssignment',
            turnNumber: 1,
            players: const [
              Player(id: 'pl1', displayName: 'Spain', isHuman: true),
            ],
          ).copyWith(
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 1,
              ),
              oldWorld: RegionData(
                provinces: [
                  Province(
                    id: 'oldWorld|p1',
                    regionId: 'oldWorld',
                    ownerId: 'pl1',
                  ),
                ],
                units: [unit],
              ),
              newWorld: const RegionData(),
            ),
          );
      harness.adapter.save(harness.box, game);
      final loadedUnit = harness.adapter
          .load(harness.box, 'withCivilianAssignment')!
          .worldState
          .oldWorld
          .units
          .single;
      expect(loadedUnit.originTileKey, 'oldWorld|p1|0|0');
      expect(loadedUnit.assignedTileKey, 'oldWorld|p1|1|0');
      expect(loadedUnit.tileKey, 'oldWorld|p1|1|0');
    });

    test('save/load round-trip includes Phase 3 combat state', () {
      final game =
          minimalSaveGame(
            id: 'phase3',
            turnNumber: 2,
            players: [
              Player(
                id: 'pl1',
                displayName: 'Spain',
                isHuman: true,
                militaryLevel: 4,
              ),
            ],
          ).copyWith(
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 2,
              ),
              oldWorld: RegionData(
                provinces: [
                  Province(
                    id: 'oldWorld|p1',
                    regionId: 'oldWorld',
                    ownerId: 'pl1',
                    fortLevel: 2,
                    terrain: 'hardwoodForest',
                  ),
                ],
                units: [
                  Unit(
                    id: 'u1',
                    type: 'grenadiers',
                    ownerId: 'pl1',
                    locationProvinceId: 'oldWorld|p1',
                    medals: 3,
                  ),
                ],
              ),
              newWorld: const RegionData(),
            ),
            minorNations: [MinorNation(id: 'min1', effectiveMilitaryLevel: 4)],
            tribes: [Tribe(id: 'tribe1', effectiveMilitaryLevel: 1)],
          );
      harness.adapter.save(harness.box, game);
      final loaded = harness.adapter.load(harness.box, 'phase3')!;
      expect(loaded.worldState.oldWorld.provinces.single.fortLevel, 2);
      expect(
        loaded.worldState.oldWorld.provinces.single.terrain,
        'hardwoodForest',
      );
      expect(loaded.worldState.oldWorld.units.single.medals, 3);
      expect(loaded.players.single.militaryLevel, 4);
      expect(loaded.minorNations.single.effectiveMilitaryLevel, 4);
      expect(loaded.tribes.single.effectiveMilitaryLevel, 1);
    });

    test('save/load round-trip includes greatPowerColorOverride', () {
      final game =
          minimalSaveGame(
            id: 'colorOverride',
            turnNumber: 1,
            players: const [
              Player(id: 'pl1', displayName: 'Spain', isHuman: true),
            ],
          ).copyWith(
            greatPowerColorOverride: {
              'gp1': [255, 0, 0],
              'gp2': [0, 255, 0],
            },
          );
      harness.adapter.save(harness.box, game);
      final loaded = harness.adapter.load(harness.box, 'colorOverride')!;
      expect(loaded.greatPowerColorOverride!['gp1'], [255, 0, 0]);
      expect(loaded.greatPowerColorOverride!['gp2'], [0, 255, 0]);
    });
  });
}
