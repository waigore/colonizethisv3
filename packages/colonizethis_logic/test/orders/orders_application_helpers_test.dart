import 'package:colonizethis_logic/src/orders/orders_application_helpers.dart';
import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('parseTileKeyCoordinates', () {
    test('returns parsed coordinates for a valid tile key', () {
      final parsed = parseTileKeyCoordinates('oldWorld|P1|12|7');
      expect(parsed, isNotNull);
      expect(parsed!.regionId, 'oldWorld');
      expect(parsed.provinceLocalId, 'P1');
      expect(parsed.x, 12);
      expect(parsed.y, 7);
    });

    test('returns null for malformed tile key', () {
      expect(parseTileKeyCoordinates('oldWorld|P1|12'), isNull);
      expect(parseTileKeyCoordinates('oldWorld|P1|x|7'), isNull);
    });
  });

  group('cancelUnitWork', () {
    test('clears work state and restores origin tile by default', () {
      final unit = Unit(
        id: 'u1',
        type: 'worker',
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|P1',
        tileKey: 'oldWorld|P1|2|2',
        originTileKey: 'oldWorld|P1|1|1',
        assignedTileKey: 'oldWorld|P1|3|3',
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: kWorkTargetBuildRoad,
          tileKey: 'oldWorld|P1|3|3',
          remainingTurns: 2,
          totalTurns: 3,
        ),
      );

      final cancelled = cancelUnitWork(unit);

      expect(cancelled.status, UnitStatus.idle);
      expect(cancelled.tileKey, 'oldWorld|P1|1|1');
      expect(cancelled.currentWork, isNull);
      expect(cancelled.originTileKey, isNull);
      expect(cancelled.assignedTileKey, isNull);
    });

    test('uses explicit restored tile override', () {
      final unit = Unit(
        id: 'u2',
        type: 'worker',
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|P1',
        tileKey: 'oldWorld|P1|2|2',
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: kWorkTargetBuildRoad,
          tileKey: 'oldWorld|P1|3|3',
          remainingTurns: 2,
          totalTurns: 3,
        ),
      );

      final cancelled = cancelUnitWork(unit, restoredTile: 'oldWorld|P1|0|0');

      expect(cancelled.tileKey, 'oldWorld|P1|0|0');
      expect(cancelled.currentWork, isNull);
    });
  });
}
