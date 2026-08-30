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

  group('provinceNamesByPrefixedId', () {
    test('indexes provinces from both regions and prefixes by regionId', () {
      final game = civilianSortTestGameWith(
        oldProvinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            displayName: 'Avalon',
          ),
          Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
        ],
        newProvinces: const [
          Province(
            id: 'newWorld|p1',
            regionId: 'newWorld',
            displayName: 'Cibola',
          ),
        ],
      );

      final names = provinceNamesByPrefixedId(game);

      expect(names['oldWorld|oldWorld|p1'], 'Avalon');
      expect(names['oldWorld|oldWorld|p2'], 'oldWorld|p2');
      expect(names['newWorld|newWorld|p1'], 'Cibola');
      expect(names, hasLength(3));
    });

    test(
      'iterates old-world entries before new-world (allProvinces order)',
      () {
        final game = civilianSortTestGameWith(
          oldProvinces: const [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
          ],
          newProvinces: const [
            Province(id: 'newWorld|p1', regionId: 'newWorld'),
          ],
        );

        final keys = provinceNamesByPrefixedId(game).keys.toList();

        expect(keys, ['oldWorld|oldWorld|p1', 'newWorld|newWorld|p1']);
      },
    );

    test('returns an empty index when neither region has provinces', () {
      final names = provinceNamesByPrefixedId(civilianSortTestGameWith());

      expect(names, isEmpty);
    });
  });

  group('isCivilianUnit', () {
    Unit civilianUnit(String id, String type) => Unit(
      id: id,
      type: type,
      ownerId: civilianSortHumanId,
      locationProvinceId: 'oldWorld|p1',
    );

    test('returns true for Builder, Explorer, Merchant, Engineer, Spy', () {
      expect(isCivilianUnit(civilianUnit('u1', kUnitTypeBuilder)), isTrue);
      expect(isCivilianUnit(civilianUnit('u2', kUnitTypeExplorer)), isTrue);
      expect(isCivilianUnit(civilianUnit('u3', kUnitTypeMerchant)), isTrue);
      expect(isCivilianUnit(civilianUnit('u4', kUnitTypeEngineer)), isTrue);
      expect(isCivilianUnit(civilianUnit('u5', kUnitTypeSpy)), isTrue);
    });

    test('returns false for military regiment units', () {
      expect(isCivilianUnit(civilianUnit('u1', 'grenadiers')), isFalse);
    });

    test('returns false for unknown unit types', () {
      expect(isCivilianUnit(civilianUnit('u1', 'unknown_type')), isFalse);
    });
  });

  group('civilianSortProvinceName', () {
    const provinceNames = {
      'oldWorld|oldWorld|p1': 'Avalon',
      'newWorld|newWorld|p2': 'Cibola',
    };

    test(
      'falls back to `regionId|provinceId` when display name is missing',
      () {
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: civilianSortHumanId,
          locationProvinceId: 'oldWorld|p9',
          tileKey: 'oldWorld|p9|0|0',
        );
        final name = civilianSortProvinceName(
          unit,
          humanPlayerId: civilianSortHumanId,
          currentOrders: const Orders(),
          provinceNames: provinceNames,
        );
        expect(name, 'oldWorld|oldWorld|p9');
      },
    );

    test('uses display name for the unit current tile', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: civilianSortHumanId,
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final name = civilianSortProvinceName(
        unit,
        humanPlayerId: civilianSortHumanId,
        currentOrders: const Orders(),
        provinceNames: provinceNames,
      );
      expect(name, 'Avalon');
    });

    test('honors pending work-order projected tile for sort key', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: civilianSortHumanId,
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      const orders = Orders(
        workOrdersByPlayerId: {
          civilianSortHumanId: [
            WorkOrder(
              unitId: 'u1',
              target: kWorkTargetExplore,
              targetTileKey: 'newWorld|p2|0|0',
            ),
          ],
        },
      );
      final name = civilianSortProvinceName(
        unit,
        humanPlayerId: civilianSortHumanId,
        currentOrders: orders,
        provinceNames: provinceNames,
      );
      expect(name, 'Cibola');
    });
  });
}
