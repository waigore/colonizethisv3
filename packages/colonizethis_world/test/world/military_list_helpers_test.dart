import 'package:colonizethis_world/src/world/military_list_helpers.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('partitionBySelectedIds', () {
    test('splits selected vs remaining by id (positive)', () {
      final items = [
        (id: 'a', v: 1),
        (id: 'b', v: 2),
        (id: 'c', v: 3),
      ];

      final out = partitionBySelectedIds(
        items: items,
        selectedIds: {'a', 'c'},
        idOf: (e) => e.id,
      );

      expect(out.selected.map((e) => e.id), ['a', 'c']);
      expect(out.remaining.map((e) => e.id), ['b']);
    });

    test('all remaining when selection empty (negative)', () {
      final items = [
        (id: 'a', v: 1),
        (id: 'b', v: 2),
      ];

      final out = partitionBySelectedIds(
        items: items,
        selectedIds: const <String>{},
        idOf: (e) => e.id,
      );

      expect(out.selected, isEmpty);
      expect(out.remaining.map((e) => e.id), ['a', 'b']);
    });
  });

  group('idsNotIn', () {
    test('preserves order of kept ids (positive)', () {
      expect(idsNotIn(['a', 'b', 'c', 'd'], {'b', 'd'}), ['a', 'c']);
    });

    test('returns empty when all removed (negative)', () {
      expect(idsNotIn(['a', 'b'], {'a', 'b'}), isEmpty);
    });
  });

  group('replaceById', () {
    test('replaces matching entry (positive)', () {
      final items = [
        (id: 'a', v: 1),
        (id: 'b', v: 2),
      ];

      final out = replaceById(
        items: items,
        id: 'b',
        replacement: (id: 'b', v: 9),
        idOf: (e) => e.id,
      );

      expect(out.map((e) => e.v), [1, 9]);
    });

    test('returns copy unchanged when id missing (negative)', () {
      final items = [
        (id: 'a', v: 1),
      ];

      final out = replaceById(
        items: items,
        id: 'missing',
        replacement: (id: 'x', v: 0),
        idOf: (e) => e.id,
      );

      expect(out.map((e) => e.id), ['a']);
      expect(identical(out, items), isFalse);
    });
  });
}
