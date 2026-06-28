import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  PlayerView view0({
    Map<String, VisibilityLevel> visibilityByTile = const {},
    Map<String, Province> provincesById = const {},
  }) {
    const playerId = 'gp1';
    final player = const Player(
      id: playerId,
      displayName: 'P',
      isHuman: false,
    );
    return PlayerView(
      playerId: playerId,
      player: player,
      ownUnitsById: const {},
      provincesById: provincesById,
      visibilityByTile: visibilityByTile,
      prospectedTiles: const {},
      diplomacyByOtherId: const {},
    );
  }

  group('provinceHasAtLeastVisibility', () {
    test('false when no tile has 4-part key for region/province', () {
      final view = view0(
        visibilityByTile: {
          'oldWorld|p1|0|0': VisibilityLevel.fogged,
        },
      );
      expect(
        provinceHasAtLeastVisibility(
          view, 'oldWorld', 'p2', VisibilityLevel.fogged,
        ),
        isFalse,
      );
    });

    test('true when a tile in province has at least min visibility', () {
      final view = view0(
        visibilityByTile: {
          'oldWorld|p1|0|0': VisibilityLevel.fogged,
        },
      );
      expect(
        provinceHasAtLeastVisibility(
          view, 'oldWorld', 'p1', VisibilityLevel.fogged,
        ),
        isTrue,
      );
    });

    test('ignores tile keys with wrong number of parts', () {
      final view = view0(
        visibilityByTile: {
          'badkey': VisibilityLevel.fullyVisible,
        },
      );
      expect(
        provinceHasAtLeastVisibility(
          view, 'oldWorld', 'p1', VisibilityLevel.fogged,
        ),
        isFalse,
      );
    });
  });

  group('tileHasAtLeastVisibility', () {
    test('true when tile has at least min level', () {
      final view = view0(
        visibilityByTile: {'t1': VisibilityLevel.fullyVisible},
      );
      expect(
        tileHasAtLeastVisibility(view, 't1', VisibilityLevel.fogged),
        isTrue,
      );
    });
    test('false when tile unknown', () {
      final view = view0();
      expect(
        tileHasAtLeastVisibility(view, 'missing', VisibilityLevel.fogged),
        isFalse,
      );
    });
  });

  group('moveSourceVisibilityOk', () {
    test('true when province has at least fogged', () {
      final view = view0(
        visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.fogged},
      );
      expect(moveSourceVisibilityOk(view, 'oldWorld', 'p1'), isTrue);
    });
  });

  group('moveDestVisibilityOk', () {
    test('true when province has at least fogged', () {
      final view = view0(
        visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.fogged},
      );
      expect(
        moveDestVisibilityOk(view, 'oldWorld', 'p1', 'inf'),
        isTrue,
      );
    });
  });

  group('workOrderVisibilityOk', () {
    WorldState worldStateTwoLandTilesP1() {
      const full = 'oldWorld|p1';
      return WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(provinces: []),
        newWorld: const RegionData(provinces: []),
        tileKeysByRegionAndProvince: {
          'oldWorld': {
            full: ['oldWorld|p1|0|0', 'oldWorld|p1|1|0'],
          },
        },
      );
    }

    test('explore requires partial reveal (known + unknown land tiles)', () {
      final view = view0(
        visibilityByTile: {
          'oldWorld|p1|0|0': VisibilityLevel.fogged,
          'oldWorld|p1|1|0': VisibilityLevel.unknown,
        },
      );
      final unit = Unit(
        id: 'u1',
        type: 'inf',
        ownerId: 'gp1',
        locationProvinceId: 'oldWorld|p1',
      );
      final ws = worldStateTwoLandTilesP1();
      expect(
        workOrderVisibilityOk(
          view,
          unit,
          kWorkTargetExplore,
          targetTileKey: 'oldWorld|p1|0|0',
          worldState: ws,
        ),
        isTrue,
      );
    });

    test('explore rejects province with no unknown land tile', () {
      final view = view0(
        visibilityByTile: {
          'oldWorld|p1|0|0': VisibilityLevel.fogged,
          'oldWorld|p1|1|0': VisibilityLevel.fogged,
        },
      );
      final unit = Unit(
        id: 'u1',
        type: 'inf',
        ownerId: 'gp1',
        locationProvinceId: 'oldWorld|p1',
      );
      final ws = worldStateTwoLandTilesP1();
      expect(
        workOrderVisibilityOk(
          view,
          unit,
          kWorkTargetExplore,
          targetTileKey: 'oldWorld|p1|0|0',
          worldState: ws,
        ),
        isFalse,
      );
    });

    test('explore rejects when worldState omitted', () {
      final view = view0(
        visibilityByTile: {
          'oldWorld|p1|0|0': VisibilityLevel.fogged,
          'oldWorld|p1|1|0': VisibilityLevel.unknown,
        },
      );
      final unit = Unit(
        id: 'u1',
        type: 'inf',
        ownerId: 'gp1',
        locationProvinceId: 'oldWorld|p1',
      );
      expect(
        workOrderVisibilityOk(
          view,
          unit,
          kWorkTargetExplore,
          targetTileKey: 'oldWorld|p1|0|0',
        ),
        isFalse,
      );
    });

    test('prospect requires at least fogged', () {
      final view = view0(
        visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.fogged},
      );
      final unit = Unit(
        id: 'u1',
        type: 'inf',
        ownerId: 'gp1',
        locationProvinceId: 'oldWorld|p1',
      );
      expect(workOrderVisibilityOk(view, unit, kWorkTargetProspect), isTrue);
    });

    test('build_improvement allows owned province', () {
      const r = 'oldWorld', p = 'p1';
      final fullId = '$r|$p';
      final view = view0(
        provincesById: {
          fullId: Province(
            id: fullId,
            regionId: r,
            displayName: 'P1',
            ownerId: 'gp1',
          ),
        },
      );
      final unit = Unit(
        id: 'u1',
        type: 'inf',
        ownerId: 'gp1',
        locationProvinceId: 'oldWorld|p1',
      );
      expect(
        workOrderVisibilityOk(view, unit, kWorkTargetBuildImprovement),
        isTrue,
      );
    });

    test('unknown workTarget returns false', () {
      final view = view0(
        visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.fullyVisible},
      );
      final unit = Unit(
        id: 'u1',
        type: 'inf',
        ownerId: 'gp1',
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      expect(
        workOrderVisibilityOk(view, unit, 'unknown_work'),
        isFalse,
      );
    });

    test('counter_spy allows owned province without fogged', () {
      const r = 'oldWorld', p = 'p1';
      final fullId = '$r|$p';
      final view = view0(
        provincesById: {
          fullId: Province(
            id: fullId,
            regionId: r,
            displayName: 'P1',
            ownerId: 'gp1',
          ),
        },
      );
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeSpy,
        ownerId: 'gp1',
        locationProvinceId: 'oldWorld|p1',
      );
      expect(
        workOrderVisibilityOk(view, unit, kWorkTargetCounterSpy),
        isTrue,
      );
    });

    test('build_fort with fogged visibility on owned province', () {
      const r = 'oldWorld', p = 'p1';
      final fullId = '$r|$p';
      final view = view0(
        provincesById: {
          fullId: Province(
            id: fullId,
            regionId: r,
            displayName: 'P1',
            ownerId: 'gp1',
          ),
        },
        visibilityByTile: {'$r|$p|0|0': VisibilityLevel.fogged},
      );
      final unit = Unit(
        id: 'u1',
        type: 'inf',
        ownerId: 'gp1',
        locationProvinceId: 'oldWorld|p1',
      );
      expect(
        workOrderVisibilityOk(view, unit, kWorkTargetBuildFort),
        isTrue,
      );
    });

    test('build_road with targetTileKey uses tile key for region and province', () {
      final view = view0(
        visibilityByTile: {'oldWorld|p2|1|1': VisibilityLevel.fogged},
        provincesById: {
          'oldWorld|p2': Province(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            displayName: 'P2',
            ownerId: 'gp1',
          ),
        },
      );
      final unit = Unit(
        id: 'u1',
        type: 'engineer',
        ownerId: 'gp1',
        locationProvinceId: 'oldWorld|p2',
      );
      expect(
        workOrderVisibilityOk(
          view,
          unit,
          kWorkTargetBuildRoad,
          targetTileKey: 'oldWorld|p2|1|1',
        ),
        isTrue,
      );
    });

    test('provinceHasAtLeastVisibility returns false when parts.length != 4', () {
      final view = view0(
        visibilityByTile: {'oldWorld|p1|0': VisibilityLevel.fullyVisible},
      );
      expect(
        provinceHasAtLeastVisibility(
          view, 'oldWorld', 'p1', VisibilityLevel.fogged,
        ),
        isFalse,
      );
    });
  });
}
