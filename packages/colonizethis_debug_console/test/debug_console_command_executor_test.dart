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

    test('returns error for invalid command', () {
      final result = executor.executeRaw(rawInput: '/bad', humanPlayerId: 'p1');
      expect(result.isError, isTrue);
      expect(result.events, isEmpty);
    });
  });
}
