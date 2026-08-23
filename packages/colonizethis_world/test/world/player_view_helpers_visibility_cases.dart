import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_test/test.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
///
/// Pure projection helpers in `lib/src/world/player_view.dart`.
/// SPEC/game/fog-and-exploration.md and SPEC/program/player-view.md.
PlayerView _view({
  String playerId = 'p1',
  Map<String, Unit> ownUnitsById = const {},
  Map<String, Province> provincesById = const {},
  Map<String, VisibilityLevel> visibilityByTile = const {},
  Set<String> prospectedTiles = const {},
  Map<String, DiplomacyRelation> diplomacyByOtherId = const {},
}) {
  return PlayerView(
    playerId: playerId,
    player: Player(id: playerId, displayName: 'P', isHuman: true),
    ownUnitsById: ownUnitsById,
    provincesById: provincesById,
    visibilityByTile: visibilityByTile,
    prospectedTiles: prospectedTiles,
    diplomacyByOtherId: diplomacyByOtherId,
  );
}

void registerPlayerViewHelpersVisibilityCases() {
  group('foreignCivilianVisibleToPlayer', () {
    test('own units are always visible', () {
      final view = _view();
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|p1',
      );
      expect(
        foreignCivilianVisibleToPlayer(
          unit: unit,
          viewerPlayerId: 'p1',
          view: view,
        ),
        isTrue,
      );
    });

    test('enemy spies are never visible', () {
      final view = _view(
        visibilityByTile: const {'tile': VisibilityLevel.fullyVisible},
      );
      final spy = Unit(
        id: 'u2',
        type: kUnitTypeSpy,
        ownerId: 'p2',
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'tile',
      );
      expect(
        foreignCivilianVisibleToPlayer(
          unit: spy,
          viewerPlayerId: 'p1',
          view: view,
        ),
        isFalse,
      );
    });

    test('foreign civilians require a tile key', () {
      final view = _view();
      final unit = Unit(
        id: 'u3',
        type: kUnitTypeExplorer,
        ownerId: 'p2',
        locationProvinceId: 'oldWorld|p1',
      );
      expect(
        foreignCivilianVisibleToPlayer(
          unit: unit,
          viewerPlayerId: 'p1',
          view: view,
        ),
        isFalse,
      );
    });

    test('foreign civilians on unknown tiles are hidden', () {
      final view = _view(
        visibilityByTile: const {'tile': VisibilityLevel.unknown},
      );
      final unit = Unit(
        id: 'u4',
        type: kUnitTypeExplorer,
        ownerId: 'p2',
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'tile',
      );
      expect(
        foreignCivilianVisibleToPlayer(
          unit: unit,
          viewerPlayerId: 'p1',
          view: view,
        ),
        isFalse,
      );
    });

    test('foreign civilians on at-least-fogged tiles are visible', () {
      final view = _view(
        visibilityByTile: const {'tile': VisibilityLevel.fogged},
      );
      final unit = Unit(
        id: 'u5',
        type: kUnitTypeExplorer,
        ownerId: 'p2',
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'tile',
      );
      expect(
        foreignCivilianVisibleToPlayer(
          unit: unit,
          viewerPlayerId: 'p1',
          view: view,
        ),
        isTrue,
      );
    });
  });

  group('PlayerView accessors', () {
    test('expose units, provinces, visibility, prospection, and relations', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|p1',
      );
      final province = const Province(
        id: 'oldWorld|p1',
        regionId: 'oldWorld',
        ownerId: 'p1',
      );
      final relation = const DiplomacyRelation(
        factionId1: 'p1',
        factionId2: 'p2',
      );
      final view = _view(
        ownUnitsById: {'u1': unit},
        provincesById: {'oldWorld|p1': province},
        visibilityByTile: const {'t1': VisibilityLevel.fullyVisible},
        prospectedTiles: const {'t1'},
        diplomacyByOtherId: {'p2': relation},
      );

      expect(view.ownUnits.single, unit);
      expect(view.provinceByRegionAndId('oldWorld', 'oldWorld|p1'), province);
      expect(view.unitsInProvince('oldWorld', 'p1').single, unit);
      expect(view.unitsInProvince('oldWorld', 'p2'), isEmpty);
      expect(view.visibilityForTile('t1'), VisibilityLevel.fullyVisible);
      expect(view.visibilityForTile('absent'), VisibilityLevel.unknown);
      expect(view.tileIsProspected('t1'), isTrue);
      expect(view.tileIsProspected('t2'), isFalse);
      expect(view.relationWith('p2'), relation);
      expect(view.relationWith('p3'), isNull);
    });
  });
}
