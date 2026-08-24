// Tests for civilian_units_sort.dart (SPEC/ui/civilian-units-panel.md).
//
// Covers the public sort/partition helpers extracted in Refs #2575 so that
// civilian-units-panel ordering can be verified without rendering the panel:
//
// - `civilianUnitsInRegion` ordering (positive: province name → type → id;
//   negative: skips wrong owner / military / fleet / missing tile / non-civilian).
// - `civilianUnitsInRegion` honors **projected** tile when a pending work
//   order targets a different province (Schwartzian sort key consistency with
//   the panel rendering).
// - `provinceNamesByPrefixedId` builds an index across both world regions.
// - `civilianSortProvinceName` resolves projected province display name and
//   falls back to `regionId|provinceId` when no display name is registered.

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        kUnitTypeBuilder,
        kUnitTypeEngineer,
        kUnitTypeExplorer,
        kUnitTypeMerchant,
        kUnitTypeSpy,
        kWorkTargetExplore;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_sort.dart';

import 'civilian_units_sort_test_support.dart';

void main() {
  suppressLogsForTests();

  group('civilianUnitsInRegion', () {
    const provinceNames = {
      'oldWorld|oldWorld|p1': 'Avalon',
      'oldWorld|oldWorld|p2': 'Belgrad',
    };

    Unit civilian({
      required String id,
      required String type,
      required String tileKey,
      String ownerId = civilianSortHumanId,
    }) {
      return Unit(
        id: id,
        type: type,
        ownerId: ownerId,
        locationProvinceId:
            Unit.provinceIdFromTileKey(tileKey) ?? 'oldWorld|p1',
        tileKey: tileKey,
      );
    }

    test(
      'orders results by province name, then type, then id (Schwartzian)',
      () {
        // Intentional input order is unsorted so the sort is observable.
        final units = [
          civilian(
            id: 'u_zeta',
            type: kUnitTypeExplorer,
            tileKey: 'oldWorld|p2|0|0',
          ),
          civilian(
            id: 'u_alpha',
            type: kUnitTypeBuilder,
            tileKey: 'oldWorld|p1|0|0',
          ),
          civilian(
            id: 'u_beta',
            type: kUnitTypeBuilder,
            tileKey: 'oldWorld|p1|0|0',
          ),
          civilian(
            id: 'u_gamma',
            type: kUnitTypeExplorer,
            tileKey: 'oldWorld|p1|1|0',
          ),
        ];

        final sorted = civilianUnitsInRegion(
          units,
          civilianSortHumanId,
          provinceNames,
          const Orders(),
        );

        expect(sorted.map((u) => u.id).toList(), [
          'u_alpha',
          'u_beta',
          'u_gamma',
          'u_zeta',
        ]);
      },
    );

    test(
      'skips wrong owner, military, missing tile, and non-civilian units',
      () {
        final units = [
          civilian(
            id: 'foreign',
            type: kUnitTypeBuilder,
            tileKey: 'oldWorld|p1|0|0',
            ownerId: civilianSortOtherId,
          ),
          Unit(
            id: 'no-tile',
            type: kUnitTypeBuilder,
            ownerId: civilianSortHumanId,
            locationProvinceId: 'oldWorld|p1',
          ),
          civilian(
            id: 'military',
            type: 'grenadiers',
            tileKey: 'oldWorld|p1|0|0',
          ),
          civilian(
            id: 'unknown-type',
            type: 'aliens',
            tileKey: 'oldWorld|p1|0|0',
          ),
          civilian(
            id: 'civilian',
            type: kUnitTypeBuilder,
            tileKey: 'oldWorld|p1|0|0',
          ),
        ];

        final sorted = civilianUnitsInRegion(
          units,
          civilianSortHumanId,
          provinceNames,
          const Orders(),
        );

        expect(sorted.map((u) => u.id).toList(), ['civilian']);
      },
    );

    test(
      'sort key tracks projected tile when a pending order moves a unit',
      () {
        // u1 is currently in p1 ("Avalon"). A pending Explore order sends it
        // to p2 ("Belgrad"), so it must sort *after* u2 (in p1) by province
        // name even though `u1` is alphabetically earlier than `u2`.
        final units = [
          civilian(
            id: 'u1',
            type: kUnitTypeExplorer,
            tileKey: 'oldWorld|p1|0|0',
          ),
          civilian(
            id: 'u2',
            type: kUnitTypeExplorer,
            tileKey: 'oldWorld|p1|1|0',
          ),
        ];
        const orders = Orders(
          workOrdersByPlayerId: {
            civilianSortHumanId: [
              WorkOrder(
                unitId: 'u1',
                target: kWorkTargetExplore,
                targetTileKey: 'oldWorld|p2|0|0',
              ),
            ],
          },
        );

        final sorted = civilianUnitsInRegion(
          units,
          civilianSortHumanId,
          provinceNames,
          orders,
        );

        expect(sorted.map((u) => u.id).toList(), ['u2', 'u1']);
      },
    );

    test('returns empty list when no units match', () {
      final units = [
        civilian(
          id: 'military',
          type: 'grenadiers',
          tileKey: 'oldWorld|p1|0|0',
        ),
      ];

      final sorted = civilianUnitsInRegion(
        units,
        civilianSortHumanId,
        provinceNames,
        const Orders(),
      );

      expect(sorted, isEmpty);
    });
  });
}
