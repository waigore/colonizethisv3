import 'package:colonizethis_setup/src/setup/seed_perturbation.dart';
import 'package:colonizethis_test/test.dart';

/// Identity-preservation contract for `perturbSeed` (Refs #3428): it must
/// reproduce the previously-inlined `Object.hash(base, salt, ...args)` values
/// so deterministic GP Old World redistribution outputs do not regress.
void main() {
  group('perturbSeed', () {
    const base = 0x1234;
    const salt = 0x5452524e; // ASCII "TRRN" terrain salt.

    test('positive: equals Object.hash for a single int arg', () {
      expect(
        perturbSeed(base, salt, args: const [7]),
        Object.hash(base, salt, 7),
      );
    });

    test('positive: equals Object.hash for heterogeneous (int+String) args', () {
      expect(
        perturbSeed(base, salt, args: const [3, 9, 'gp_blue']),
        Object.hash(base, salt, 3, 9, 'gp_blue'),
      );
    });

    test('positive: equals Object.hash with no extra args', () {
      expect(perturbSeed(base, salt), Object.hash(base, salt));
    });

    test('positive: deterministic for identical inputs', () {
      expect(
        perturbSeed(base, salt, args: const [1, 2]),
        perturbSeed(base, salt, args: const [1, 2]),
      );
    });

    test('negative: differing args generally yield different seeds', () {
      expect(
        perturbSeed(base, salt, args: const ['gp_red']),
        isNot(perturbSeed(base, salt, args: const ['gp_blue'])),
      );
    });

    test('negative: differing salt generally yields different seeds', () {
      expect(
        perturbSeed(base, salt, args: const [1]),
        isNot(perturbSeed(base, 0x5245444f, args: const [1])),
      );
    });
  });
}
