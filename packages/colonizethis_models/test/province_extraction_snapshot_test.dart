import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('ProvinceExtractionSnapshot (Refs #4002)', () {
    test('toJson/fromJson round-trip preserves fields', () {
      const snap = ProvinceExtractionSnapshot(
        ownerId: 'pl1',
        byCommodity: {
          'grain': ProvinceExtractionCommodityTotals(
            effective: 1,
            full: 5,
            tileKeys: ['oldWorld|p1|0|0'],
          ),
          'iron': ProvinceExtractionCommodityTotals(
            effective: 5,
            full: 5,
            tileKeys: ['oldWorld|p1|1|0'],
          ),
        },
      );
      final restored = ProvinceExtractionSnapshot.fromJson(snap.toJson());
      expect(restored, snap);
    });

    test('WorldState legacy JSON without snapshot field loads empty map', () {
      final json = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ).toJson();
      json.remove('lastTurnProvinceExtractionByProvinceId');
      final loaded = WorldState.fromJson(json);
      expect(loaded.lastTurnProvinceExtractionByProvinceId, isEmpty);
    });

    test('WorldState round-trips non-empty snapshot map', () {
      final state = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'pl1'),
          ],
        ),
        newWorld: const RegionData(),
        lastTurnProvinceExtractionByProvinceId: const {
          'oldWorld|p1': ProvinceExtractionSnapshot(
            ownerId: 'pl1',
            byCommodity: {
              'grain': ProvinceExtractionCommodityTotals(effective: 6, full: 6),
            },
          ),
        },
      );
      final loaded = WorldState.fromJson(state.toJson());
      expect(
        loaded.lastTurnProvinceExtractionByProvinceId,
        state.lastTurnProvinceExtractionByProvinceId,
      );
      expect(loaded, state);
    });

    test('display gate drops ownership-mismatched snapshot', () {
      const snap = ProvinceExtractionSnapshot(
        ownerId: 'oldOwner',
        byCommodity: {
          'grain': ProvinceExtractionCommodityTotals(effective: 3, full: 3),
        },
      );
      expect(
        provinceExtractionSnapshotForDisplay(
          snapshot: snap,
          currentOwnerId: 'newOwner',
        ),
        isNull,
      );
      expect(
        provinceExtractionSnapshotForDisplay(
          snapshot: snap,
          currentOwnerId: 'oldOwner',
        ),
        snap,
      );
    });
  });
}
