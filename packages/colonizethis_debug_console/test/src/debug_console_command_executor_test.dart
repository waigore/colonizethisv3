import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'debug_console_command_executor_cases.dart';
import 'debug_console_command_executor_readonly_cases.dart';

void main() {
  group('DebugConsoleCommandExecutor', () {
    const executor = DebugConsoleCommandExecutor();

    test('emits spawn and credit events for valid commands', () {
      for (final row in executorSpawnCreditSuccessCases) {
        expectExecutorSpawnCredit(executor, row);
      }
    });

    test('clamp messages include requested and credited amounts', () {
      for (final row in executorClampCases) {
        expectExecutorSpawnCredit(executor, row);
      }
    });

    test('returns error for invalid command', () {
      final result = executor.executeRaw(rawInput: '/bad', humanPlayerId: 'p1');
      expect(result.isError, isTrue);
      expect(result.events, isEmpty);
    });

    test('emits flip_province and reveal_province events', () {
      for (final row in executorProvinceCases) {
        expectExecutorProvince(executor, row);
      }
    });

    test('get_tile_basic_info read-only outcomes', () {
      for (final row in executorGetTileCases) {
        expectExecutorReadOnly(executor, row);
      }
    });

    test('existing mutating commands still emit expected event types', () {
      for (final row in executorMutatingTypeCases) {
        final result = executor.executeRaw(
          rawInput: row.$1,
          humanPlayerId: 'p1',
        );
        expect(result.events.single.runtimeType, row.$2, reason: row.$1);
      }
    });

    test('list_players formats, fallback, and unavailable outcomes', () {
      for (final row in executorListPlayersCases) {
        expectExecutorReadOnly(executor, row);
      }
    });

    test('observe global, resolve, eliminated, and unknown outcomes', () {
      for (final row in executorObserveCases) {
        expectExecutorObserve(executor, row);
      }
    });

    test('set_diplomacy one-faction, two-faction, and unknown action', () {
      for (final row in executorDiplomacyCases) {
        expectExecutorDiplomacy(executor, row);
      }
    });
  });
}

void expectExecutorProvince(
  DebugConsoleCommandExecutor executor,
  ExecutorProvinceCase row,
) {
  final result = executor.executeRaw(rawInput: row.input, humanPlayerId: 'p1');
  expect(result.isError, isFalse, reason: row.input);
  final event = result.events.single;
  expect(event.runtimeType, row.eventType, reason: row.input);
  switch (event) {
    case FlipDebugProvinceOwnershipEvent(
      :final humanPlayerId,
      :final regionId,
      :final provinceDisplayName,
      :final fullProvinceId,
    ):
      expect(humanPlayerId, 'p1', reason: row.input);
      expect(regionId, row.regionId, reason: row.input);
      expect(provinceDisplayName, row.provinceDisplayName, reason: row.input);
      expect(fullProvinceId, row.fullProvinceId, reason: row.input);
    case RevealDebugProvinceEvent(
      :final humanPlayerId,
      :final target,
      :final targetIsFullProvinceId,
    ):
      expect(humanPlayerId, 'p1', reason: row.input);
      expect(target, row.target, reason: row.input);
      expect(
        targetIsFullProvinceId,
        row.targetIsFullProvinceId,
        reason: row.input,
      );
    default:
      fail('${row.input}: unexpected ${event.runtimeType}');
  }
}

void expectExecutorDiplomacy(
  DebugConsoleCommandExecutor executor,
  ExecutorDiplomacyCase row,
) {
  final result = executor.executeRaw(rawInput: row.input, humanPlayerId: 'p1');
  expect(result.isError, row.isError, reason: row.input);
  if (row.isError) {
    expect(result.events, isEmpty, reason: row.input);
    return;
  }
  final event = result.events.single as SetDebugDiplomacyRelationEvent;
  expect(event.humanPlayerId, 'p1', reason: row.input);
  expect(event.factionA, row.factionA, reason: row.input);
  expect(event.factionB, row.factionB, reason: row.input);
  expect(event.action, row.action, reason: row.input);
  for (final fragment in row.messageContains) {
    expect(result.message, contains(fragment), reason: row.input);
  }
}
