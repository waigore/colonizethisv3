import 'package:colonizethis_map/src/region_data_access.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

WorldState _worldState() => WorldState(
  turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
  oldWorld: RegionData(
    provinces: const [Province(id: 'oldWorld|p1', regionId: 'oldWorld')],
    units: [
      Unit(
        id: 'u_ow',
        type: 'pikemen',
        ownerId: 'gp1',
        locationProvinceId: 'oldWorld|p1',
      ),
    ],
  ),
  newWorld: RegionData(
    provinces: const [Province(id: 'newWorld|p1', regionId: 'newWorld')],
    units: [
      Unit(
        id: 'u_nw',
        type: 'pikemen',
        ownerId: 'tribe1',
        locationProvinceId: 'newWorld|p1',
      ),
    ],
  ),
);

void main() {
  group('regionDataForMapRegionId (Refs #3459 AC3)', () {
    test('old world id returns the old-world region data', () {
      final region = regionDataForMapRegionId(_worldState(), 'oldWorld');
      expect(region.provinces.single.id, 'oldWorld|p1');
      expect(region.units.single.id, 'u_ow');
    });

    test('new world id returns the new-world region data', () {
      final region = regionDataForMapRegionId(_worldState(), 'newWorld');
      expect(region.provinces.single.id, 'newWorld|p1');
      expect(region.units.single.id, 'u_nw');
    });

    test('unknown region id throws ArgumentError', () {
      expect(
        () => regionDataForMapRegionId(_worldState(), 'moon'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
