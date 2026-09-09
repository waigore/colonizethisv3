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

    test('ignores duplicate consecutive push', () {
      final history = DebugConsoleHistory();
      history.push('/add_money 100');
      history.push('/add_money 100');

      expect(history.snapshot(), ['/add_money 100']);
    });

    test('older and newer return null on empty history', () {
      final history = DebugConsoleHistory();
      expect(history.older(), isNull);
      expect(history.newer(), isNull);
    });

    test('older at oldest entry stays on oldest', () {
      final history = DebugConsoleHistory();
      history.push('/help');
      expect(history.older(), '/help');
      expect(history.older(), '/help');
    });

    test('snapshot returns unmodifiable list', () {
      final history = DebugConsoleHistory();
      history.push('/list_players');
      final snapshot = history.snapshot();
      expect(
        () => snapshot.add('/spawn_civilian explorer'),
        throwsUnsupportedError,
      );
      history.push('/observe');
      expect(snapshot, ['/list_players']);
    });
  });
}
