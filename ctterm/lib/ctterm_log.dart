// ctterm logging. SPEC/tui/ctterm.md §5. Use prefixes tui:, tui:menu:, tui:save:, tui:nav:, etc.
// File output via basic_logger_file (ctterm.log in the ctterm data directory).

import 'dart:io';

import 'package:basic_logger/basic_logger.dart';
import 'package:basic_logger_file/basic_logger_file.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

/// Resolves ctterm data directory. Same convention as save_service (SPEC/tui/ctterm.md §5).
String _cttermDataDir(String? override) {
  if (override != null && override.isNotEmpty) return override;
  final env = Platform.environment;
  if (Platform.isLinux && env.containsKey('XDG_DATA_HOME')) {
    return path.join(env['XDG_DATA_HOME']!, 'colonizethis_ctterm');
  }
  final home = env['HOME'] ?? env['USERPROFILE'] ?? '.';
  return path.join(home, '.colonizethis_ctterm');
}

/// Path to ctterm.log after init. Null until [initCttermLogging] is called.
String? get cttermLogPath => _logFilePath;

String? _logFilePath;
BasicLogger? _fileLogger;

/// Formats a [LogEvent] to one or more lines (message + optional error/stackTrace).
List<String> _formatLogEvent(LogEvent e) {
  final time = e.time.toUtc().toIso8601String();
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

/// Initializes ctterm logging. Call from main() before runApp.
/// [dataDirOverride] is the same as --data-dir (ctterm data dir); ctterm.log is created there.
/// Console: standard [Logger]. File: [BasicLogger] + [FileOutputLogger] (buffered, non-blocking).
void initCttermLogging([String? dataDirOverride]) {
  Logger.level = Level.debug;

  final dir = _cttermDataDir(dataDirOverride);
  final dirFile = Directory(dir);
  if (!dirFile.existsSync()) {
    dirFile.createSync(recursive: true);
  }
  _logFilePath = path.join(dir, 'ctterm.log');

  try {
    _fileLogger = BasicLogger('ctterm');
    _fileLogger!.attachLogger(FileOutputLogger(
      'ctterm',
      dir: dir,
      ext: '.log',
      bufferSize: 20,
    ));
  } on Object {
    _fileLogger = null;
    _logFilePath = null;
    return;
  }

  Logger.addLogListener((LogEvent e) {
    final logger = _fileLogger;
    if (logger == null) {
      return;
    }
    final lines = _formatLogEvent(e);
    for (final line in lines) {
      try {
        logger.info(line);
      } on Exception {
        // Ignore so file logging never blocks or breaks the app.
      }
    }
  });
}
