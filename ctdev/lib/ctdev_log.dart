// ctdev file and in-memory logging. SPEC/program/ctdev-logging.md.

import 'dart:async';
import 'dart:io';

import 'package:basic_logger/basic_logger.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:logger/logger.dart';
import 'package:logging/logging.dart' as logging;
import 'package:path/path.dart' as path;

/// Used by [_CtdevPlainFileOutputLogger]; exposed for unit tests (no second timestamp).
@visibleForTesting
String ctdevFileOutputFormattedLine(logging.LogRecord logRec) =>
    '${logRec.message}\n';

/// Day-file sink with the same buffering/append contract as `basic_logger_file`
/// `FileOutputLogger` 0.1.3 (that class is `final`, so format cannot be specialized here).
/// Prepends only the formatted message body — canonical time is already in [formatLogEvent].
final class _CtdevPlainFileOutputLogger extends OutputLogger {
  final List<logging.LogRecord> _buffer = [];
  late int _bufferSize;
  late String _dir;
  late String _ext;
  late final String __logName;
  late final logging.Logger _parentLogger;

  _CtdevPlainFileOutputLogger(
    String parentName, {
    required logging.Logger parentLogger,
    String selfname = 'file',
    bool selfonly = false,
    required String dir,
    String ext = '.log',
    int bufferSize = 100,
  }) : super(parentName, selfname: selfname, listening: false) {
    _parentLogger = parentLogger;
    _bufferSize = bufferSize;
    _dir = dir;
    _ext = ext;
    __logName = '$parentName.$selfname';
    _parentLogger.onRecord.listen((logging.LogRecord logRec) {
      if (selfonly) {
        if (__logName == logRec.loggerName) _buffer.add(logRec);
      } else {
        if (parentName == logRec.loggerName) _buffer.add(logRec);
      }
      if (_buffer.length >= _bufferSize) {
        output();
      }
    });
  }

  @override
  String Function(logging.LogRecord logRec) get format =>
      (logging.LogRecord logRec) => ctdevFileOutputFormattedLine(logRec);

  @override
  String get name => __logName;

  @override
  void output([logging.LogRecord? record]) {
    if (_buffer.isEmpty) {
      return;
    }
    final bufs = <String>[];
    for (final logging.LogRecord log in _buffer) {
      bufs.add(format(log));
    }
    final logfile = path.join(
      _dir,
      '${DateTime.now().toLocal().toString().substring(0, 10)}$_ext',
    );
    unawaited(
      File(logfile)
          .writeAsString(bufs.join(), mode: FileMode.writeOnlyAppend)
          .whenComplete(() {
        _buffer.clear();
        bufs.clear();
      }),
    );
  }
}

const int _uiLogMaxLines = 10;

final List<String> _preSimBuffer = [];
String? _sessionId;
BasicLogger? _fileLogger;
String? _logsDir;
final List<String> _uiLogLines = [];

/// Resolves project root: parent of current if CWD ends with 'ctdev', else current.
String _projectRoot() {
  final current = Directory.current.path;
  return path.basename(current) == 'ctdev'
      ? path.dirname(current)
      : current;
}

/// Returns the current sim session ID if a session has been started.
String? get sessionId => _sessionId;

/// Returns the path to the current day's log file when a session is active, or null.
String? get sessionLogPath {
  if (_sessionId == null || _logsDir == null) return null;
  final now = DateTime.now().toLocal();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return path.join(_logsDir!, '$dateStr.log');
}

/// Adds a formatted line to the UI log (info+ only). Keeps last [_uiLogMaxLines] lines.
void addUiLine(String line) {
  _uiLogLines.add(line);
  while (_uiLogLines.length > _uiLogMaxLines) {
    _uiLogLines.removeAt(0);
  }
}

/// Clears the in-memory UI log (call at start of each turn).
void clearUiLog() {
  _uiLogLines.clear();
}

/// Returns the last [max] UI log lines (unmodifiable view).
List<String> getLastUiLogLines([int max = _uiLogMaxLines]) {
  final start = _uiLogLines.length > max ? _uiLogLines.length - max : 0;
  return List.unmodifiable(_uiLogLines.sublist(start));
}

/// Formats a [LogEvent] into one or more lines (message + optional error/stackTrace).
List<String> formatLogEvent(LogEvent e) {
  final time = formatOperatorLogTimestamp(e.time);
  final levelName = e.level.name.toUpperCase();
  final msg = e.message is String ? e.message as String : e.message.toString();
  final lines = <String>['$time $levelName $msg'];
  if (e.error != null) {
    lines.add('  error: ${e.error}');
  }
  if (e.stackTrace != null) {
    lines.add('  stackTrace: ${e.stackTrace}');
  }
  return lines;
}

/// Forwards [lines] to the file logger (if active) or appends to pre-sim buffer.
void _writeLines(List<String> lines) {
  if (_fileLogger != null) {
    for (final line in lines) {
      _fileLogger!.info(line);
    }
  } else {
    _preSimBuffer.addAll(lines);
  }
}

/// Starts a sim session: ensures logs dir under project root, attaches file logger, replays pre-sim buffer.
void startSimSession(String id) {
  if (_sessionId != null) return;
  _sessionId = id;
  final projectRoot = _projectRoot();
  final logsDir = path.join(projectRoot, 'logs');
  _logsDir = logsDir;
  final dir = Directory(logsDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final basicLogger = BasicLogger('ctdev');
  basicLogger.attachLogger(_CtdevPlainFileOutputLogger(
    basicLogger.name,
    parentLogger: basicLogger.logger,
    dir: logsDir,
    bufferSize: 50,
  ));
  _fileLogger = basicLogger;
  for (final line in _preSimBuffer) {
    _fileLogger!.info(line);
  }
  _preSimBuffer.clear();
}

/// Initializes ctdev logging. Call from main() before runApp.
void initCtdevLogging() {
  logging.hierarchicalLoggingEnabled = true;
  logging.Logger.root.level = logging.Level.ALL;
  Logger.level = Level.debug;
  Logger.addLogListener((LogEvent e) {
    final lines = formatLogEvent(e);
    _writeLines(lines);
    if (e.level.value >= Level.info.value) {
      addUiLine(lines.first);
    }
  });
}

/// Test-only helper to reset in-memory ctdev logging state between tests.
/// Not used by production code.
void resetCtdevLoggingForTest() {
  _preSimBuffer.clear();
  _sessionId = null;
  _fileLogger = null;
  _logsDir = null;
  _uiLogLines.clear();
}
