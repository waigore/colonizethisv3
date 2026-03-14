// Tests for main menu Load Game enabled logic. SPEC/tui/ctterm.md.

import 'package:ctterm/menu_logic.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('isLoadGameEnabled', () {
    test('returns false when no saves exist', () {
      expect(isLoadGameEnabled([]), isFalse);
    });

    test('returns true when at least one save exists', () {
      expect(isLoadGameEnabled(['game1']), isTrue);
      expect(isLoadGameEnabled(['a', 'b']), isTrue);
    });
  });
}
