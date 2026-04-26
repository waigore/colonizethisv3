import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  suppressLogsForTests();

  group('DebugConsoleCommandParser', () {
    const parser = DebugConsoleCommandParser();

    test('parses spawn civilian command with defaults', () {
      final result = parser.parse('/spawn_civilian explorer');
      expect(result.isError, isFalse);
      expect(result.command, isNotNull);
      expect(result.command!.unitType, kUnitTypeExplorer);
      expect(result.command!.count, 1);
    });

    test('parses rail builder aliases', () {
      final result = parser.parse('/spawn_civilian rail_builder 2');
      expect(result.isError, isFalse);
      expect(result.command!.unitType, kUnitTypeRailBuilder);
      expect(result.command!.count, 2);
    });

    test('rejects invalid command', () {
      final result = parser.parse('/unknown');
      expect(result.isError, isTrue);
      expect(result.message, contains('Unknown command'));
    });
  });
}
