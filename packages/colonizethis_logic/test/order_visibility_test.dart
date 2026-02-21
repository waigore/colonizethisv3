import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  PlayerView _view({
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
      final view = _view(
        visibilityByTile: {
          'oldWorld|p1|0|0': VisibilityLevel.revealed,
        },
      );
      expect(
        provinceHasAtLeastVisibility(
          view, 'oldWorld', 'p2', VisibilityLevel.revealed,
        ),
        isFalse,
      );
    });

    test('true when a tile in province has at least min visibility', () {
      final view = _view(
        visibilityByTile: {
          'oldWorld|p1|0|0': VisibilityLevel.fogged,
        },
      );
      expect(
        provinceHasAtLeastVisibility(
          view, 'oldWorld', 'p1', VisibilityLevel.revealed,
        ),
        isTrue,
      );
    });

    test('ignores tile keys with wrong number of parts', () {
      final view = _view(
        visibilityByTile: {
          'badkey': VisibilityLevel.fullyVisible,
        },
      );
      expect(
        provinceHasAtLeastVisibility(
          view, 'oldWorld', 'p1', VisibilityLevel.revealed,
        ),
        isFalse,
      );
    });
  });

  group('tileHasAtLeastVisibility', () {
    test('true when tile has at least min level', () {
      final view = _view(
        visibilityByTile: {'t1': VisibilityLevel.fullyVisible},
      );
      expect(
        tileHasAtLeastVisibility(view, 't1', VisibilityLevel.revealed),
        isTrue,
      );
    });
    test('false when tile unknown', () {
      final view = _view();
      expect(
        tileHasAtLeastVisibility(view, 'missing', VisibilityLevel.revealed),
        isFalse,
      );
    });
  });

  group('moveSourceVisibilityOk', () {
    test('true when province has at least revealed', () {
      final view = _view(
        visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.revealed},
      );
      expect(moveSourceVisibilityOk(view, 'oldWorld', 'p1'), isTrue);
    });
  });

  group('moveDestVisibilityOk', () {
    test('true when province has at least revealed', () {
      final view = _view(
        visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.revealed},
      );
      expect(
        moveDestVisibilityOk(view, 'oldWorld', 'p1', 'inf'),
        isTrue,
      );
    });
  });

  group('workOrderVisibilityOk', () {
    test('explore requires at least revealed', () {
      final view = _view(
        visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.revealed},
      );
      const unit = Unit(
        id: 'u1',
        type: 'inf',
        ownerId: 'gp1',
        provinceId: 'oldWorld|p1',
      );
      expect(
        workOrderVisibilityOk(view, unit, 'explore'),
        isTrue,
      );
    });

    test('prospect requires at least fogged', () {
      final view = _view(
        visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.fogged},
      );
      const unit = Unit(
        id: 'u1',
        type: 'inf',
        ownerId: 'gp1',
        provinceId: 'oldWorld|p1',
      );
      expect(
        workOrderVisibilityOk(view, unit, 'prospect'),
        isTrue,
      );
    });

    test('build_improvement allows owned province', () {
      const r = 'oldWorld', p = 'p1';
      final fullId = '$r|$p';
      final view = _view(
        provincesById: {
          fullId: Province(
            id: fullId,
            regionId: r,
            displayName: 'P1',
            ownerId: 'gp1',
          ),
        },
      );
      const unit = Unit(
        id: 'u1',
        type: 'inf',
        ownerId: 'gp1',
        provinceId: 'oldWorld|p1',
      );
      expect(
        workOrderVisibilityOk(view, unit, 'build_improvement'),
        isTrue,
      );
    });

    test('unknown workTarget returns false', () {
      final view = _view(
        visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.fullyVisible},
      );
      const unit = Unit(
        id: 'u1',
        type: 'inf',
        ownerId: 'gp1',
        provinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      expect(workOrderVisibilityOk(view, unit, 'unknown_work'), isFalse);
    });

    test('counter_spy allows owned province without fogged', () {
      const r = 'oldWorld', p = 'p1';
      final fullId = '$r|$p';
      final view = _view(
        provincesById: {
          fullId: Province(
            id: fullId,
            regionId: r,
            displayName: 'P1',
            ownerId: 'gp1',
          ),
        },
      );
      const unit = Unit(
        id: 'u1',
        type: 'Spy',
        ownerId: 'gp1',
        provinceId: 'oldWorld|p1',
      );
      expect(
        workOrderVisibilityOk(view, unit, 'counter_spy'),
        isTrue,
      );
    });

    test('build_fort with fogged visibility on owned province', () {
      const r = 'oldWorld', p = 'p1';
      final fullId = '$r|$p';
      final view = _view(
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
      const unit = Unit(
        id: 'u1',
        type: 'inf',
        ownerId: 'gp1',
        provinceId: 'oldWorld|p1',
      );
      expect(
        workOrderVisibilityOk(view, unit, 'build_fort'),
        isTrue,
      );
    });

    test('build_road with targetTileKey uses tile key for region and province', () {
      final view = _view(
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
      const unit = Unit(
        id: 'u1',
        type: 'engineer',
        ownerId: 'gp1',
        provinceId: 'oldWorld|p2',
      );
      expect(
        workOrderVisibilityOk(view, unit, 'build_road', 'oldWorld|p2|1|1'),
        isTrue,
      );
    });

    test('provinceHasAtLeastVisibility returns false when parts.length != 4', () {
      final view = _view(
        visibilityByTile: {'oldWorld|p1|0': VisibilityLevel.fullyVisible},
      );
      expect(
        provinceHasAtLeastVisibility(
          view, 'oldWorld', 'p1', VisibilityLevel.revealed,
        ),
        isFalse,
      );
    });
  });
}
