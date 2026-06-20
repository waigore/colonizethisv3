// Unit tests for the shared selection-dispatch contract extracted from the
// military / naval unit panels (Refs #3546 AC4 / AC10).

import 'package:colonizethis_app/features/game/widgets/units/shared/units_multi_selection_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitsMultiSelectionController', () {
    late UnitsMultiSelectionController controller;

    setUp(() => controller = UnitsMultiSelectionController());

    test('starts empty', () {
      expect(controller.isEmpty, isTrue);
      expect(controller.length, 0);
      expect(controller.contains('a'), isFalse);
      expect(controller.selectedIds, isEmpty);
    });

    test('toggle adds then removes an id', () {
      controller.toggle('a');
      expect(controller.contains('a'), isTrue);
      expect(controller.length, 1);

      controller.toggle('a');
      expect(controller.contains('a'), isFalse);
      expect(controller.isEmpty, isTrue);
    });

    test('clear empties the selection', () {
      controller
        ..toggle('a')
        ..toggle('b');
      controller.clear();
      expect(controller.isEmpty, isTrue);
    });

    test('replaceWith drops stale ids and adds the new set', () {
      controller
        ..toggle('a')
        ..toggle('stale');
      controller.replaceWith(['a', 'b']);
      expect(controller.selectedIds, {'a', 'b'});
      expect(controller.contains('stale'), isFalse);
    });

    test('retainOnly prunes ids absent from validIds and reports change', () {
      controller
        ..toggle('a')
        ..toggle('b')
        ..toggle('gone');
      final changed = controller.retainOnly(['a', 'b']);
      expect(changed, isTrue);
      expect(controller.selectedIds, {'a', 'b'});
    });

    test('retainOnly returns false when nothing is pruned', () {
      controller
        ..toggle('a')
        ..toggle('b');
      final changed = controller.retainOnly(['a', 'b', 'c']);
      expect(changed, isFalse);
      expect(controller.selectedIds, {'a', 'b'});
    });

    group('headerValue (tri-state)', () {
      test('returns false for an empty row set', () {
        expect(controller.headerValue(const <String>[]), isFalse);
      });

      test('returns false when no rows are selected', () {
        expect(controller.headerValue(['a', 'b']), isFalse);
      });

      test('returns null for a partial selection', () {
        controller.toggle('a');
        expect(controller.headerValue(['a', 'b']), isNull);
      });

      test('returns true when every row is selected', () {
        controller
          ..toggle('a')
          ..toggle('b');
        expect(controller.headerValue(['a', 'b']), isTrue);
      });

      test('ignores selected ids that are not in the row set', () {
        controller
          ..toggle('a')
          ..toggle('b')
          ..toggle('off-screen');
        // Only the visible rows {a, b} are considered.
        expect(controller.headerValue(['a', 'b']), isTrue);
      });
    });

    group('selectAllOrClear', () {
      test('selects every row from an empty selection', () {
        controller.selectAllOrClear(['a', 'b', 'c']);
        expect(controller.selectedIds, {'a', 'b', 'c'});
      });

      test('selects every row from a partial selection (dropping stale ids)', () {
        controller
          ..toggle('a')
          ..toggle('stale');
        controller.selectAllOrClear(['a', 'b']);
        expect(controller.selectedIds, {'a', 'b'});
      });

      test('clears when every row is already selected', () {
        controller
          ..toggle('a')
          ..toggle('b');
        controller.selectAllOrClear(['a', 'b']);
        expect(controller.isEmpty, isTrue);
      });

      test('no-op shape for an empty row set leaves selection empty', () {
        controller.selectAllOrClear(const <String>[]);
        expect(controller.isEmpty, isTrue);
      });
    });
  });
}
