import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  const turn = TurnState(phase: TurnPhase.orders, turnNumber: 0);
  final pOld = Province(
    id: 'oldWorld|P1',
    regionId: kRegionOldWorld,
    ownerId: 'gp1',
  );
  final pNew = Province(
    id: 'newWorld|P2',
    regionId: kRegionNewWorld,
    ownerId: 'gp2',
  );

  WorldState makeWorld({
    List<Province> oldProvinces = const [],
    List<Province> newProvinces = const [],
  }) {
    return WorldState(
      turnState: turn,
      oldWorld: RegionData(provinces: oldProvinces),
      newWorld: RegionData(provinces: newProvinces),
    );
  }

  group('WorldStateProvinceLookup.allProvincesById (Refs #2836 item 4)', () {
    test('contains provinces from both regions keyed by id', () {
      final ws = makeWorld(oldProvinces: [pOld], newProvinces: [pNew]);

      expect(ws.allProvincesById.length, 2);
      expect(ws.allProvincesById['oldWorld|P1'], pOld);
      expect(ws.allProvincesById['newWorld|P2'], pNew);
    });

    test('prefers old-world province when both regions share an id', () {
      final dupOld = Province(
        id: 'dup',
        regionId: kRegionOldWorld,
        ownerId: 'gp1',
      );
      final dupNew = Province(
        id: 'dup',
        regionId: kRegionNewWorld,
        ownerId: 'gp2',
      );
      final ws = makeWorld(oldProvinces: [dupOld], newProvinces: [dupNew]);

      expect(ws.allProvincesById['dup']!.ownerId, 'gp1');
    });

    test(
      'returns the identical map across repeated reads for one WorldState',
      () {
        final ws = makeWorld(oldProvinces: [pOld], newProvinces: [pNew]);

        final first = ws.allProvincesById;
        final second = ws.allProvincesById;

        expect(identical(first, second), isTrue);
      },
    );

    test('different WorldState copies receive their own cached map', () {
      final wsA = makeWorld(oldProvinces: [pOld], newProvinces: [pNew]);
      final wsB = wsA.copyWith(turnState: turn);

      expect(identical(wsA.allProvincesById, wsB.allProvincesById), isFalse);
    });

    test('mutation of returned map throws UnsupportedError', () {
      final ws = makeWorld(oldProvinces: [pOld]);

      expect(
        () => ws.allProvincesById['oldWorld|P1'] = pOld,
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('empty regions yield empty map', () {
      final ws = makeWorld();

      expect(ws.allProvincesById, isEmpty);
    });
  });
}
