// Tests for ctterm logging. SPEC/tui/ctterm.md.

import 'package:ctterm/ctterm_log.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('ctterm_log', () {
    test('cttermLogPath is null before init', () {
      // Before init, the path should be null
      expect(cttermLogPath, isNull);
    });

    test('initCttermLogging can be called without parameters', () {
      // Should not throw - will create default directory
      // Note: This may create a directory in the file system
      expect(() => initCttermLogging(), returnsNormally);
    });

    test('initCttermLogging can be called with custom directory', () {
      // Use a temp directory to avoid polluting the real file system
      expect(
        () => initCttermLogging('/tmp/ctterm_test_${DateTime.now().millisecondsSinceEpoch}'),
        returnsNormally,
      );
    });
  });
}
