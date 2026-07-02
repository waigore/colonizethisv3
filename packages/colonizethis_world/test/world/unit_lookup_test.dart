import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/src/world/unit_lookup.dart';

const turn = TurnState(phase: TurnPhase.orders, turnNumber: 0);

final uOld = Unit(
  id: 'u-old',
  type: kUnitTypeExplorer,
  ownerId: 'p1',
  locationProvinceId: 'oldWorld|P1',
  tileKey: 'oldWorld|P1|0|0',
);
final uNew = Unit(
  id: 'u-new',
  type: kUnitTypeBuilder,
  ownerId: 'p1',
  locationProvinceId: 'newWorld|P2',
  tileKey: 'newWorld|P2|0|0',
);

final uOld1 = Unit(
  id: 'u-old-1',
  type: kUnitTypeExplorer,
  ownerId: 'p1',
  locationProvinceId: 'oldWorld|P1',
  tileKey: 'oldWorld|P1|0|0',
);
final uOld2 = Unit(
  id: 'u-old-2',
  type: kUnitTypeBuilder,
  ownerId: 'p1',
  locationProvinceId: 'oldWorld|P1',
  tileKey: 'oldWorld|P1|0|1',
);
final uNew1 = Unit(
  id: 'u-new-1',
  type: kUnitTypeBuilder,
  ownerId: 'p1',
  locationProvinceId: 'newWorld|P2',
  tileKey: 'newWorld|P2|0|0',
);
final uNew2 = Unit(
  id: 'u-new-2',
  type: kUnitTypeExplorer,
  ownerId: 'p2',
  locationProvinceId: 'newWorld|P3',
  tileKey: 'newWorld|P3|0|0',
);

WorldState makeWorld({
  List<Unit> oldUnits = const [],
  List<Unit> newUnits = const [],
}) {
  return TestFixtures.worldStateAtOrdersPhase(
    turnNumber: 0,
    oldWorld: RegionData(units: oldUnits),
    newWorld: RegionData(units: newUnits),
  );
}

void main() {
group('WorldStateUnitLookup.tryGetUnitById', () {
    final uOld = Unit(
      id: 'u-old',
      type: kUnitTypeExplorer,
      ownerId: 'p1',
      locationProvinceId: 'oldWorld|P1',
      tileKey: 'oldWorld|P1|0|0',
    );
    final uNew = Unit(
      id: 'u-new',
      type: kUnitTypeExplorer,
      ownerId: 'p1',
      locationProvinceId: 'newWorld|P2',
      tileKey: 'newWorld|P2|0|0',
    );

    test('returns unit from old world when present', () {
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: RegionData(units: [uOld]),
        newWorld: const RegionData(),
      );
      expect(ws.tryGetUnitById('u-old'), uOld);
    });

    test('returns unit from new world when not in old world', () {
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: const RegionData(),
        newWorld: RegionData(units: [uNew]),
      );
      expect(ws.tryGetUnitById('u-new'), uNew);
    });

    test('returns null when id is absent', () {
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: RegionData(units: [uOld]),
        newWorld: RegionData(units: [uNew]),
      );
      expect(ws.tryGetUnitById('none'), isNull);
    });

    test('prefers old world when both lists contain the same id', () {
      final inOld = Unit(
        id: 'dup',
        type: kUnitTypeExplorer,
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|P1',
        tileKey: 'oldWorld|P1|0|0',
      );
      final inNew = Unit(
        id: 'dup',
        type: kUnitTypeBuilder,
        ownerId: 'p2',
        locationProvinceId: 'newWorld|P2',
        tileKey: 'newWorld|P2|0|0',
      );
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: RegionData(units: [inOld]),
        newWorld: RegionData(units: [inNew]),
      );
      expect(ws.tryGetUnitById('dup')!.type, kUnitTypeExplorer);
    });

    test('500+ units per region matches linear old-then-new scan (AC-3)', () {
      const n = 520;
      final oldUnits = List<Unit>.generate(
        n,
        (i) => Unit(
          id: 'old-$i',
          type: kUnitTypeExplorer,
          ownerId: 'p1',
          locationProvinceId: 'oldWorld|P1',
          tileKey: 'oldWorld|P1|0|0',
        ),
      );
      final newUnits = List<Unit>.generate(
        n,
        (i) => Unit(
          id: 'new-$i',
          type: kUnitTypeBuilder,
          ownerId: 'p2',
          locationProvinceId: 'newWorld|P2',
          tileKey: 'newWorld|P2|0|0',
        ),
      );
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: RegionData(units: oldUnits),
        newWorld: RegionData(units: newUnits),
      );

      Unit? linearLookup(String unitId) {
        for (final u in ws.oldWorld.units) {
          if (u.id == unitId) return u;
        }
        for (final u in ws.newWorld.units) {
          if (u.id == unitId) return u;
        }
        return null;
      }

      for (var i = 0; i < n; i++) {
        final id = 'old-$i';
        expect(ws.tryGetUnitById(id), same(linearLookup(id)));
      }
      for (var i = 0; i < n; i++) {
        final id = 'new-$i';
        expect(ws.tryGetUnitById(id), same(linearLookup(id)));
      }
      expect(ws.tryGetUnitById('missing'), isNull);
    });
  });

  group('WorldStateUnitLookup.tryGetRegionIdForUnit', () {
    final uOld = Unit(
      id: 'r-old',
      type: kUnitTypeExplorer,
      ownerId: 'p1',
      locationProvinceId: 'oldWorld|P1',
      tileKey: 'oldWorld|P1|0|0',
    );
    final uNew = Unit(
      id: 'r-new',
      type: kUnitTypeExplorer,
      ownerId: 'p1',
      locationProvinceId: 'newWorld|P2',
      tileKey: 'newWorld|P2|0|0',
    );

    test('returns oldWorld when unit list is in old world', () {
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: RegionData(units: [uOld]),
        newWorld: const RegionData(),
      );
      expect(ws.tryGetRegionIdForUnit(uOld), kRegionOldWorld);
    });

    test('returns newWorld when unit is only in new world', () {
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: const RegionData(),
        newWorld: RegionData(units: [uNew]),
      );
      expect(ws.tryGetRegionIdForUnit(uNew), kRegionNewWorld);
    });

    test('returns null when unit id is in neither region', () {
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      expect(ws.tryGetRegionIdForUnit(uOld), isNull);
    });

    test('prefers old world when same id exists in both regions', () {
      final a = Unit(
        id: 'same',
        type: kUnitTypeExplorer,
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|P1',
        tileKey: 'oldWorld|P1|0|0',
      );
      final b = Unit(
        id: 'same',
        type: kUnitTypeBuilder,
        ownerId: 'p2',
        locationProvinceId: 'newWorld|P2',
        tileKey: 'newWorld|P2|0|0',
      );
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 0,
        oldWorld: RegionData(units: [a]),
        newWorld: RegionData(units: [b]),
      );
      expect(ws.tryGetRegionIdForUnit(b), kRegionOldWorld);
    });
  });

  group('WorldStateUnitLookup.allUnitsById (Refs #2836 AC 2)', () {
    test('contains units from both regions keyed by id', () {
      final ws = makeWorld(oldUnits: [uOld], newUnits: [uNew]);

      expect(ws.allUnitsById.length, 2);
      expect(ws.allUnitsById['u-old'], uOld);
      expect(ws.allUnitsById['u-new'], uNew);
    });

    test('matches unitsByIdFromWorld content', () {
      final ws = makeWorld(oldUnits: [uOld], newUnits: [uNew]);

      expect(ws.allUnitsById, unitsByIdFromWorld(ws));
    });

    test('prefers old-world unit when both regions share an id', () {
      final dupOld = Unit(
        id: 'dup',
        type: kUnitTypeExplorer,
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|P1',
        tileKey: 'oldWorld|P1|0|0',
      );
      final dupNew = Unit(
        id: 'dup',
        type: kUnitTypeBuilder,
        ownerId: 'p2',
        locationProvinceId: 'newWorld|P2',
        tileKey: 'newWorld|P2|0|0',
      );
      final ws = makeWorld(oldUnits: [dupOld], newUnits: [dupNew]);

      expect(ws.allUnitsById['dup']!.type, kUnitTypeExplorer);
    });

    test('returns the identical map across repeated reads for one WorldState '
        '(cached by ExpandoIndex on the WorldState identity)', () {
      final ws = makeWorld(oldUnits: [uOld], newUnits: [uNew]);

      final first = ws.allUnitsById;
      final second = ws.allUnitsById;

      expect(identical(first, second), isTrue);
    });

    test('different WorldState copies receive their own cached map', () {
      final wsA = makeWorld(oldUnits: [uOld], newUnits: [uNew]);
      final wsB = wsA.copyWith(turnState: turn);

      expect(identical(wsA, wsB), isFalse);
      expect(identical(wsA.allUnitsById, wsB.allUnitsById), isFalse);
      expect(wsA.allUnitsById, wsB.allUnitsById);
    });

    test('returned map throws when caller attempts to mutate it', () {
      final ws = makeWorld(oldUnits: [uOld], newUnits: [uNew]);
      final units = ws.allUnitsById;

      expect(() => units.remove('u-old'), throwsUnsupportedError);
      expect(() => units['injected'] = uOld, throwsUnsupportedError);
      expect(units.clear, throwsUnsupportedError);
    });

    test('Map<String, Unit>.from(world.allUnitsById) is a writable copy that '
        'does not contaminate the cached view', () {
      final ws = makeWorld(oldUnits: [uOld], newUnits: [uNew]);
      final mutable = Map<String, Unit>.from(ws.allUnitsById);

      mutable.remove('u-old');
      mutable['injected'] = uNew;

      expect(mutable.containsKey('u-old'), isFalse);
      expect(mutable['injected'], uNew);
      expect(ws.allUnitsById.containsKey('u-old'), isTrue);
      expect(ws.allUnitsById.containsKey('injected'), isFalse);
    });

    test('empty regions yield an empty unmodifiable map', () {
      final ws = makeWorld();

      expect(ws.allUnitsById, isEmpty);
      expect(() => ws.allUnitsById['x'] = uOld, throwsUnsupportedError);
    });

    test('tryGetUnitById and allUnitsById agree on every id', () {
      const n = 64;
      final oldUnits = List<Unit>.generate(
        n,
        (i) => Unit(
          id: 'old-$i',
          type: kUnitTypeExplorer,
          ownerId: 'p1',
          locationProvinceId: 'oldWorld|P1',
          tileKey: 'oldWorld|P1|0|0',
        ),
      );
      final newUnits = List<Unit>.generate(
        n,
        (i) => Unit(
          id: 'new-$i',
          type: kUnitTypeBuilder,
          ownerId: 'p2',
          locationProvinceId: 'newWorld|P2',
          tileKey: 'newWorld|P2|0|0',
        ),
      );
      final ws = makeWorld(oldUnits: oldUnits, newUnits: newUnits);
      final map = ws.allUnitsById;

      for (var i = 0; i < n; i++) {
        final oid = 'old-$i';
        final nid = 'new-$i';
        expect(map[oid], same(ws.tryGetUnitById(oid)));
        expect(map[nid], same(ws.tryGetUnitById(nid)));
      }
      expect(map.containsKey('missing'), isFalse);
    });
  });

group('militaryTypeCountsByPlayer', () {
    test('matches per-player regiment and ship counters', () {
      final game = TestFixtures.minimalGame(
        oldWorld: RegionData(
          provinces: const [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'p1'),
            Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'p2'),
          ],
          units: [
            Unit(
              id: 'u1',
              ownerId: 'p1',
              type: 'grenadiers',
              locationProvinceId: 'oldWorld|p1',
            ),
            Unit(
              id: 'u2',
              ownerId: 'p1',
              type: 'grenadiers',
              locationProvinceId: 'oldWorld|p1',
            ),
            Unit(
              id: 'u3',
              ownerId: 'p2',
              type: 'cavalry',
              locationProvinceId: 'oldWorld|p2',
            ),
          ],
        ),
        newWorld: RegionData(
          provinces: const [
            Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'p1'),
          ],
          units: [
            Unit(
              id: 'u4',
              ownerId: 'p1',
              type: 'artillery',
              locationProvinceId: 'newWorld|n1',
            ),
          ],
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
          Player(id: 'p3', displayName: 'P3', isHuman: false),
        ],
      );
      final world = game.worldState.copyWith(
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'p1',
            regionId: 'oldWorld',
            seaZoneId: 'oldWorld|sea1',
            ships: [
              ShipInstance(id: 's1', typeId: 'carrack'),
              ShipInstance(id: 's2', typeId: 'carrack'),
              ShipInstance(id: 's3', typeId: 'fluyte'),
            ],
          ),
          Fleet(
            id: 'f2',
            ownerId: 'p2',
            regionId: 'oldWorld',
            seaZoneId: 'oldWorld|sea2',
            ships: [ShipInstance(id: 's4', typeId: 'brig')],
          ),
        ],
      );

      final aggregated = militaryTypeCountsByPlayer(world);

      for (final playerId in const ['p1', 'p2', 'p3']) {
        expect(
          aggregated.regimentCountsByPlayerId[playerId] ??
              const <String, int>{},
          regimentTypeCountsForPlayer(world, playerId),
        );
        expect(
          aggregated.shipCountsByPlayerId[playerId] ?? const <String, int>{},
          shipTypeCountsForPlayer(world, playerId),
        );
      }
    });
  });

  group(
    'WorldStateUnitLookup.mutableUnitListsByRegion (Refs #2836 AC 5)',
    () {
      test('returns both regions keyed by canonical region ids', () {
        final ws = makeWorld(oldUnits: [uOld1, uOld2], newUnits: [uNew1]);

        final result = ws.mutableUnitListsByRegion();

        expect(result.keys.toSet(), {kRegionOldWorld, kRegionNewWorld});
        expect(result[kRegionOldWorld], [uOld1, uOld2]);
        expect(result[kRegionNewWorld], [uNew1]);
      });

      test('returns empty lists for empty regions', () {
        final ws = makeWorld();

        final result = ws.mutableUnitListsByRegion();

        expect(result[kRegionOldWorld], isEmpty);
        expect(result[kRegionNewWorld], isEmpty);
      });

      test(
        'returned lists are independent copies — mutating does not change '
        'source WorldState',
        () {
          final ws = makeWorld(
            oldUnits: [uOld1, uOld2],
            newUnits: [uNew1],
          );

          final result = ws.mutableUnitListsByRegion();
          result[kRegionOldWorld]!.removeLast();
          result[kRegionNewWorld]!.add(uNew2);

          expect(ws.oldWorld.units, [uOld1, uOld2]);
          expect(ws.newWorld.units, [uNew1]);
        },
      );

      test(
        'two successive calls produce independent list copies (no shared '
        'mutable state between calls)',
        () {
          final ws = makeWorld(
            oldUnits: [uOld1, uOld2],
            newUnits: [uNew1],
          );

          final first = ws.mutableUnitListsByRegion();
          final second = ws.mutableUnitListsByRegion();

          expect(
            identical(first[kRegionOldWorld], second[kRegionOldWorld]),
            isFalse,
          );
          expect(
            identical(first[kRegionNewWorld], second[kRegionNewWorld]),
            isFalse,
          );

          first[kRegionOldWorld]!.add(uOld1);
          expect(second[kRegionOldWorld], [uOld1, uOld2]);
        },
      );
    },
  );

}
