import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('ProvinceExtractionSnapshot (Refs #4064)', () {
    test('round-trips commodity totals and capitalGrainBonus', () {
      const snap = ProvinceExtractionSnapshot(
        ownerId: 'gp1',
        capitalGrainBonus: 2,
        byCommodity: {
          'grain': ProvinceExtractionCommodityTotals(
            effective: 3,
            full: 3,
            tileKeys: ['oldWorld|p1|0|0'],
          ),
        },
      );
      final restored = ProvinceExtractionSnapshot.fromJson(snap.toJson());
      expect(restored, snap);
      expect(restored.capitalGrainBonus, 2);
    });

    test('provinceExtractionSnapshotForDisplay ownership gate', () {
      const snap = ProvinceExtractionSnapshot(
        ownerId: 'gp1',
        byCommodity: {
          'grain': ProvinceExtractionCommodityTotals(effective: 1, full: 1),
        },
      );
      expect(
        provinceExtractionSnapshotForDisplay(
          snapshot: snap,
          currentOwnerId: 'gp1',
        ),
        snap,
      );
      expect(
        provinceExtractionSnapshotForDisplay(
          snapshot: snap,
          currentOwnerId: 'gp2',
        ),
        isNull,
      );
    });

    test('legacy WorldState JSON key lastTurnProvinceExtractionByProvinceId is ignored', () {
      final state = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      final json = state.toJson();
      json['lastTurnProvinceExtractionByProvinceId'] = {
        'oldWorld|p1': {
          'ownerId': 'gp1',
          'byCommodity': {
            'grain': {'effective': 1, 'full': 1},
          },
        },
      };
      final loaded = WorldState.fromJson(json);
      expect(loaded, state);
      expect(loaded.toJson().containsKey('lastTurnProvinceExtractionByProvinceId'), isFalse);
    });
  });
}
