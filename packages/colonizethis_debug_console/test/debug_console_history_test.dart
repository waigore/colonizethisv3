import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('DebugConsoleHistory', () {
    test('navigates older and newer commands', () {
      final history = DebugConsoleHistory();
      history.push('/spawn_civilian explorer');
      history.push('/spawn_civilian builder 2');

      expect(history.older(), '/spawn_civilian builder 2');
      expect(history.older(), '/spawn_civilian explorer');
      expect(history.newer(), '/spawn_civilian builder 2');
      expect(history.newer(), '');
    });
  });
}
