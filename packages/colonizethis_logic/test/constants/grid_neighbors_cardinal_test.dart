import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test(
    'kGridNeighborsCardinal4 preserves canonical cardinal traversal ordering '
    '(Refs #2391 — connectivity/setup alignment)',
    () {
      expect(
        kGridNeighborsCardinal4,
        const <(int, int)>[(0, -1), (1, 0), (0, 1), (-1, 0)],
      );
    },
  );
}
