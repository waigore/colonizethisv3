import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_logger/package_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

void main() {
  group('CtLogger', () {
    late List<LogEvent> capturedEvents;
    late void Function(LogEvent) listener;

    setUp(() {
      capturedEvents = [];
      listener = (e) => capturedEvents.add(e);
      Logger.addLogListener(listener);
      Logger.level = Level.debug;
    });

    tearDown(() {
      Logger.removeLogListener(listener);
      capturedEvents.clear();
      Logger.level = Level.info;
    });

    test('prefixes message with info level', () {
      final log = CtLogger('logic');
      log.i('test message');

      expect(capturedEvents.length, 1);
      expect(capturedEvents[0].message, 'logic: test message');
      expect(capturedEvents[0].level, Level.info);
    });

    test('prefixes message with debug level', () {
      final log = CtLogger('ai');
      log.d('decision made');

      expect(capturedEvents.length, 1);
      expect(capturedEvents[0].message, 'ai: decision made');
      expect(capturedEvents[0].level, Level.debug);
    });

    test('prefixes message with warning level', () {
      final log = CtLogger('map');
      log.w('missing tile');

      expect(capturedEvents.length, 1);
      expect(capturedEvents[0].message, 'map: missing tile');
      expect(capturedEvents[0].level, Level.warning);
    });

    test('prefixes message with error level', () {
      final log = CtLogger('save');
      log.e('failed to save');

      expect(capturedEvents.length, 1);
      expect(capturedEvents[0].message, 'save: failed to save');
      expect(capturedEvents[0].level, Level.error);
    });

    test('handles error and stackTrace parameters', () {
      final log = CtLogger('logic');
      final error = Exception('test error');
      final stackTrace = StackTrace.current;
      log.e('operation failed', error: error, stackTrace: stackTrace);

      expect(capturedEvents.length, 1);
      expect(capturedEvents[0].message, 'logic: operation failed');
      expect(capturedEvents[0].error, error);
      expect(capturedEvents[0].stackTrace, stackTrace);
    });

    test('warning with error and stackTrace', () {
      final log = CtLogger('game');
      final error = Exception('test warning');
      final stackTrace = StackTrace.current;
      log.w('operation warning', error: error, stackTrace: stackTrace);

      expect(capturedEvents.length, 1);
      expect(capturedEvents[0].message, 'game: operation warning');
      expect(capturedEvents[0].level, Level.warning);
      expect(capturedEvents[0].error, error);
      expect(capturedEvents[0].stackTrace, stackTrace);
    });

    test('package logger creates logger with package prefix', () {
      expect(packageLogger().prefix, 'logger');
    });

    test('package logger subPrefix creates compound prefix', () {
      expect(packageLogger('ct').prefix, 'logger.ct');
    });
  });

  group('prefixes', () {
    test('allLogPrefixes contains expected prefixes', () {
      expect(allLogPrefixes, contains('ctdev'));
      expect(allLogPrefixes, contains('logic'));
      expect(allLogPrefixes, contains('ai'));
      expect(allLogPrefixes, contains('data'));
      expect(allLogPrefixes, contains('map'));
      expect(allLogPrefixes, contains('save'));
      expect(allLogPrefixes, contains('tui'));
      expect(allLogPrefixes, contains('game'));
      expect(allLogPrefixes, contains('app'));
    });

    test('kLogPrefix constants have correct values', () {
      expect(kLogPrefixLogic, 'logic');
      expect(kLogPrefixAi, 'ai');
      expect(kLogPrefixData, 'data');
      expect(kLogPrefixMap, 'map');
      expect(kLogPrefixSave, 'save');
      expect(kLogPrefixTui, 'tui');
      expect(kLogPrefixGame, 'game');
      expect(kLogPrefixApp, 'app');
      expect(kLogPrefixCtdev, 'ctdev');
    });
  });
}
