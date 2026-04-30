import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('DebugConsoleCommandExecutor', () {
    const executor = DebugConsoleCommandExecutor();

    test('emits spawn event for valid command', () {
      final result = executor.executeRaw(
        rawInput: '/spawn_civilian builder 3',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      expect(result.events, hasLength(1));
      final event = result.events.single as SpawnDebugCivilianAtCapitalEvent;
      expect(event.humanPlayerId, 'p1');
      expect(event.unitType, kUnitTypeBuilder);
      expect(event.count, 3);
    });

    test('emits treasury credit event for add_money', () {
      final result = executor.executeRaw(
        rawInput: '/add_money 500',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      expect(result.events, hasLength(1));
      final event = result.events.single as CreditDebugTreasuryEvent;
      expect(event.humanPlayerId, 'p1');
      expect(event.requestedAmount, 500);
      expect(event.creditedAmount, 500);
      expect(result.message, contains('500'));
    });

    test('executor message for clamped add_money includes both amounts', () {
      final result = executor.executeRaw(
        rawInput: '/add_money 20000',
        humanPlayerId: 'p1',
      );
      expect(result.isError, isFalse);
      final event = result.events.single as CreditDebugTreasuryEvent;
      expect(event.requestedAmount, 20000);
      expect(event.creditedAmount, kDebugConsoleMaxTreasuryCreditAmount);
      expect(result.message, contains('20000'));
      expect(result.message, contains('9999'));
    });

    test('returns error for invalid command', () {
      final result = executor.executeRaw(rawInput: '/bad', humanPlayerId: 'p1');
      expect(result.isError, isTrue);
      expect(result.events, isEmpty);
    });
  });
}
