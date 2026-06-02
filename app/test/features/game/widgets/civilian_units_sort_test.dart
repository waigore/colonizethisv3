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

import 'package:colonizethis_app/features/game/widgets/civilian_units_sort.dart';

const _humanId = 'gp1';
const _otherId = 'gp2';

Game _gameWith({
  List<Unit> oldUnits = const [],
  List<Unit> newUnits = const [],
  List<Province> oldProvinces = const [],
  List<Province> newProvinces = const [],
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: oldProvinces, units: oldUnits),
      newWorld: RegionData(provinces: newProvinces, units: newUnits),
    ),
    players: const [
      Player(id: _humanId, displayName: 'Human', isHuman: true),
      Player(id: _otherId, displayName: 'Other', isHuman: false),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

void main() {
  suppressLogsForTests();

  group('provinceNamesByPrefixedId', () {
    test('indexes provinces from both regions and prefixes by regionId', () {
      final game = _gameWith(
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
  });

  group('isCivilianUnit', () {
    Unit civilianUnit(String id, String type) => Unit(
          id: id,
          type: type,
          ownerId: _humanId,
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
          ownerId: _humanId,
          locationProvinceId: 'oldWorld|p9',
          tileKey: 'oldWorld|p9|0|0',
        );
        final name = civilianSortProvinceName(
          unit,
          humanPlayerId: _humanId,
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
        ownerId: _humanId,
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final name = civilianSortProvinceName(
        unit,
        humanPlayerId: _humanId,
        currentOrders: const Orders(),
        provinceNames: provinceNames,
      );
      expect(name, 'Avalon');
    });

    test('honors pending work-order projected tile for sort key', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: _humanId,
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      const orders = Orders(
        workOrdersByPlayerId: {
          _humanId: [
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
        humanPlayerId: _humanId,
        currentOrders: orders,
        provinceNames: provinceNames,
      );
      expect(name, 'Cibola');
    });
  });

  group('civilianUnitsInRegion', () {
    const provinceNames = {
      'oldWorld|oldWorld|p1': 'Avalon',
      'oldWorld|oldWorld|p2': 'Belgrad',
    };

    Unit civilian({
      required String id,
      required String type,
      required String tileKey,
      String ownerId = _humanId,
    }) {
      return Unit(
        id: id,
        type: type,
        ownerId: ownerId,
        locationProvinceId: Unit.provinceIdFromTileKey(tileKey) ?? 'oldWorld|p1',
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
          _humanId,
          provinceNames,
          const Orders(),
        );

        expect(
          sorted.map((u) => u.id).toList(),
          ['u_alpha', 'u_beta', 'u_gamma', 'u_zeta'],
        );
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
            ownerId: _otherId,
          ),
          Unit(
            id: 'no-tile',
            type: kUnitTypeBuilder,
            ownerId: _humanId,
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
          _humanId,
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
            _humanId: [
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
          _humanId,
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
        _humanId,
        provinceNames,
        const Orders(),
      );

      expect(sorted, isEmpty);
    });
  });
}
