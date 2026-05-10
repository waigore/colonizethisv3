// Unit tests for session log buffer. SPEC/program/debug-log-viewer.md.

import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';
import 'package:session_log_buffer/session_log_buffer.dart';

void main() {
  group('SessionLogBuffer', () {
    setUp(() {
      SessionLogBuffer.resetForTest();
    });

    test('add stores entry and getFiltered returns it', () {
      final buffer = SessionLogBuffer.instance;
      buffer.add(LogEvent(Level.info, 'logic: test'));
      final filtered = buffer.getFiltered();
      expect(filtered.length, 1);
      expect(filtered.first.message, 'logic: test');
      expect(filtered.first.level, Level.info);
      expect(filtered.first.prefix, 'logic');
    });

    test('getFiltered with empty selection returns all (default show all)', () {
      final buffer = SessionLogBuffer.instance;
      buffer.add(LogEvent(Level.info, 'logic: test'));
      final filtered =
          buffer.getFiltered(selectedPrefixes: {}, selectedLevels: {});
      expect(filtered.length, 1);
    });

    test('getFiltered with matching prefix returns entry', () {
      final buffer = SessionLogBuffer.instance;
      buffer.add(LogEvent(Level.info, 'logic: test'));
      final filtered = buffer.getFiltered(
        selectedPrefixes: {'logic'},
        selectedLevels: {Level.info},
      );
      expect(filtered.length, 1);
    });

    test('getFiltered with non-matching prefix returns empty', () {
      final buffer = SessionLogBuffer.instance;
      buffer.add(LogEvent(Level.info, 'logic: test'));
      final filtered = buffer.getFiltered(
        selectedPrefixes: {'ai'},
        selectedLevels: {Level.info},
      );
      expect(filtered, isEmpty);
    });

    test('dotted logger tag buckets under known top-level prefix for filters', () {
      final buffer = SessionLogBuffer.instance;
      buffer.add(LogEvent(Level.info, 'ctdev.running_game: started'));
      expect(buffer.entries.first.prefix, 'ctdev');
      final filtered = buffer.getFiltered(
        selectedPrefixes: {'ctdev'},
        selectedLevels: {Level.info},
      );
      expect(filtered.length, 1);
    });

    test('getFiltered with non-matching level returns empty', () {
      final buffer = SessionLogBuffer.instance;
      buffer.add(LogEvent(Level.debug, 'logic: test'));
      final filtered = buffer.getFiltered(
        selectedPrefixes: {'logic'},
        selectedLevels: {Level.error},
      );
      expect(filtered, isEmpty);
    });

    test('displayLines include error and stackTrace when present', () {
      final buffer = SessionLogBuffer.instance;
      final err = StateError('oops');
      final stack = StackTrace.current;
      buffer.add(LogEvent(Level.error, 'save: failed',
          error: err, stackTrace: stack));
      final filtered = buffer.getFiltered();
      expect(filtered.length, 1);
      final lines = filtered.first.displayLines;
      expect(lines.length, greaterThanOrEqualTo(2));
      expect(lines.any((l) => l.contains('error:')), isTrue);
    });

    test('formattedLine uses canonical operator timestamp prefix', () {
      final buffer = SessionLogBuffer.instance;
      buffer.add(LogEvent(Level.info, 'logic: hi'));
      final line = buffer.entries.single.formattedLine;
      expect(
        RegExp(
          r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}(Z|[+-]\d{2}:\d{2}) INFO ',
        ).hasMatch(line),
        isTrue,
      );
      expect(line.endsWith('logic: hi'), isTrue);
    });

    test('buffer is bounded when over maxEntries', () {
      final buffer = SessionLogBuffer(maxEntries: 5);
      for (var i = 0; i < 10; i++) {
        buffer.add(LogEvent(Level.debug, 'log: $i'));
      }
      final entries = buffer.entries;
      expect(entries.length, 5);
      expect(entries.first.message, contains('5'));
      expect(entries.last.message, contains('9'));
    });

    test('resetForTest clears entries', () {
      final buffer = SessionLogBuffer.instance;
      buffer.add(LogEvent(Level.info, 'x: test'));
      expect(buffer.entries.length, 1);
      SessionLogBuffer.resetForTest();
      expect(SessionLogBuffer.instance.entries, isEmpty);
    });
  });
}
