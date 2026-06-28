import 'package:colonizethis_world/src/world/civilian_ownership_legality.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart' show kWorkTargetBuildRoad;

import '../test_fixtures.dart';
void main() {
  group('relocateIllegalCiviliansInChangedProvinces', () {
    const ow = 'oldWorld';
    const changedProvinceId = '$ow|P1';
    const changedTile = '$ow|P1|0|0';
    const unchangedProvinceId = '$ow|P2';
    const unchangedTile = '$ow|P2|0|0';
    const capitalProvinceId = '$ow|C1';
    const capitalTile = '$ow|C1|0|0';

    Game baseGame({
      required List<Unit> units,
      Player? owner,
      List<Province>? oldWorldProvinces,
    }) {
      return TestFixtures.minimalGame(
        turnNumber: 3,
        oldWorld: RegionData(
          provinces:
              oldWorldProvinces ??
              const [
                Province(id: changedProvinceId, regionId: ow, ownerId: 'new_owner'),
                Province(id: unchangedProvinceId, regionId: ow, ownerId: 'new_owner'),
                Province(id: capitalProvinceId, regionId: ow, ownerId: 'gp2'),
              ],
          units: units,
        ),
        players: [
          owner ??
              const Player(
                id: 'gp2',
                displayName: 'GP 2',
                isHuman: false,
                capitalProvinceId: capitalProvinceId,
                capitalTile: CapitalTile(regionId: ow, provinceId: 'C1', x: 0, y: 0),
              ),
          const Player(id: 'new_owner', displayName: 'New Owner', isHuman: false),
        ],
      );
    }

    test('relocates illegal civilian in changed province and normalizes state', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: 'gp2',
        locationProvinceId: changedProvinceId,
        tileKey: changedTile,
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: kWorkTargetBuildRoad,
          tileKey: changedTile,
          totalTurns: 2,
          remainingTurns: 1,
        ),
        originTileKey: changedTile,
        assignedTileKey: changedTile,
      );
      final result = relocateIllegalCiviliansInChangedProvinces(
        baseGame(units: [unit]),
        changedProvinceIds: {changedProvinceId},
      );
      final relocated = result.worldState.oldWorld.units.single;
      expect(relocated.tileKey, capitalTile);
      expect(relocated.locationProvinceId, capitalProvinceId);
      expect(relocated.status, UnitStatus.idle);
      expect(relocated.currentWork, isNull);
      expect(relocated.originTileKey, isNull);
      expect(relocated.assignedTileKey, isNull);
    });

    test(
      'relocates idle civilian with stale assignment tracking but no currentWork',
      () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: 'gp2',
        locationProvinceId: changedProvinceId,
        tileKey: changedTile,
        status: UnitStatus.idle,
        originTileKey: changedTile,
        assignedTileKey: changedTile,
      );
      final result = relocateIllegalCiviliansInChangedProvinces(
        baseGame(units: [unit]),
        changedProvinceIds: {changedProvinceId},
      );
      final relocated = result.worldState.oldWorld.units.single;
      expect(relocated.tileKey, capitalTile);
      expect(relocated.locationProvinceId, capitalProvinceId);
      expect(relocated.status, UnitStatus.idle);
      expect(relocated.currentWork, isNull);
      expect(relocated.originTileKey, isNull);
      expect(relocated.assignedTileKey, isNull);
    });

    test('does not evaluate civilians outside changed provinces', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: 'gp2',
        locationProvinceId: unchangedProvinceId,
        tileKey: unchangedTile,
      );
      final result = relocateIllegalCiviliansInChangedProvinces(
        baseGame(units: [unit]),
        changedProvinceIds: {changedProvinceId},
      );
      final unchanged = result.worldState.oldWorld.units.single;
      expect(unchanged.tileKey, unchangedTile);
      expect(unchanged.locationProvinceId, unchangedProvinceId);
    });

    test('throws hard error when owner capital tile cannot be resolved', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: 'gp2',
        locationProvinceId: changedProvinceId,
        tileKey: changedTile,
      );
      final ownerWithoutCapital = const Player(
        id: 'gp2',
        displayName: 'GP 2',
        isHuman: false,
      );
      expect(
        () => relocateIllegalCiviliansInChangedProvinces(
          baseGame(units: [unit], owner: ownerWithoutCapital),
          changedProvinceIds: {changedProvinceId},
        ),
        throwsStateError,
      );
    });

    test('throws hard error when owner capital province cannot be resolved', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: 'gp2',
        locationProvinceId: changedProvinceId,
        tileKey: changedTile,
      );
      final provincesWithoutCapital = const [
        Province(id: changedProvinceId, regionId: ow, ownerId: 'new_owner'),
        Province(id: unchangedProvinceId, regionId: ow, ownerId: 'new_owner'),
      ];
      expect(
        () => relocateIllegalCiviliansInChangedProvinces(
          baseGame(units: [unit], oldWorldProvinces: provincesWithoutCapital),
          changedProvinceIds: {changedProvinceId},
        ),
        throwsStateError,
      );
    });
  });
}
