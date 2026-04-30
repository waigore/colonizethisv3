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
      expect(result.invocation, isNotNull);
      final inv = result.invocation!;
      expect(inv, isA<DebugConsoleSpawnCivilianAtCapital>());
      final spawn = inv as DebugConsoleSpawnCivilianAtCapital;
      expect(spawn.unitType, kUnitTypeExplorer);
      expect(spawn.count, 1);
    });

    test('parses rail builder aliases', () {
      final result = parser.parse('/spawn_civilian rail_builder 2');
      expect(result.isError, isFalse);
      final spawn = result.invocation! as DebugConsoleSpawnCivilianAtCapital;
      expect(spawn.unitType, kUnitTypeRailBuilder);
      expect(spawn.count, 2);
    });

    test('rejects invalid command', () {
      final result = parser.parse('/unknown');
      expect(result.isError, isTrue);
      expect(result.message, contains('Unknown command'));
    });

    test('rejects non-integer spawn count', () {
      final result = parser.parse('/spawn_civilian explorer nope');
      expect(result.isError, isTrue);
      expect(result.message, contains('Count must be an integer'));
    });

    test('rejects spawn count above max limit', () {
      final result = parser.parse('/spawn_civilian explorer 26');
      expect(result.isError, isTrue);
      expect(result.message, contains('between 1 and 25'));
    });

    test('parses add_money with equal requested and credited', () {
      final result = parser.parse('/add_money 100');
      expect(result.isError, isFalse);
      final credit = result.invocation! as DebugConsoleTreasuryCredit;
      expect(credit.requestedAmount, 100);
      expect(credit.creditedAmount, 100);
    });

    test('clamps add_money above cap in parser', () {
      final result = parser.parse('/add_money 12000');
      expect(result.isError, isFalse);
      final credit = result.invocation! as DebugConsoleTreasuryCredit;
      expect(credit.requestedAmount, 12000);
      expect(credit.creditedAmount, kDebugConsoleMaxTreasuryCreditAmount);
    });

    test('rejects non-integer add_money amount', () {
      final result = parser.parse('/add_money abc');
      expect(result.isError, isTrue);
      expect(result.message, contains('Amount must be an integer'));
    });

    test('rejects add_money below 1', () {
      final result = parser.parse('/add_money 0');
      expect(result.isError, isTrue);
      expect(result.message, contains('at least 1'));
    });

    test('help lists add_money bounds', () {
      final result = parser.parse('/help');
      expect(result.isError, isTrue);
      expect(result.message, contains('/add_money'));
      expect(result.message, contains('9999'));
    });
  });
}
