import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_logic/src/diplomacy/diplomacy_relation_lookup.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('firstPlayerRowIndexById', () {
    test('empty list yields empty map', () {
      expect(firstPlayerRowIndexById(const <Player>[]), isEmpty);
    });

    test('maps each id to its first row index', () {
      const players = [
        Player(id: 'a', displayName: 'A', isHuman: false),
        Player(id: 'b', displayName: 'B', isHuman: false),
        Player(id: 'c', displayName: 'C', isHuman: false),
      ];
      expect(
        firstPlayerRowIndexById(players),
        equals(<String, int>{'a': 0, 'b': 1, 'c': 2}),
      );
    });

    test('duplicate ids keep earliest index (indexWhere semantics)', () {
      const players = [
        Player(id: 'dup', displayName: 'First', isHuman: false),
        Player(id: 'other', displayName: 'X', isHuman: false),
        Player(id: 'dup', displayName: 'Second', isHuman: false),
      ];
      expect(
        firstPlayerRowIndexById(players)['dup'],
        0,
      );
    });
  });
}
