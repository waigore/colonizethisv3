import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
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

  WorldState makeWorld({
    List<Unit> oldUnits = const [],
    List<Unit> newUnits = const [],
  }) {
    return WorldState(
      turnState: turn,
      oldWorld: RegionData(units: oldUnits),
      newWorld: RegionData(units: newUnits),
    );
  }

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
}
