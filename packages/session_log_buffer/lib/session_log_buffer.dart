// Session log buffer for debug log viewer. SPEC/program/debug-log-viewer.md.

import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:logger/logger.dart';

/// Default maximum number of log entries to retain (oldest dropped when exceeded).
const int defaultMaxEntries = 5000;

/// Known log prefixes used in the project (ctdev, logic, ai, data, map, save, game, app).
/// Used for filter options in the viewer.
const List<String> knownPrefixes = [
  'ctdev',
  'logic',
  'ai',
  'data',
  'map',
  'save',
  'game',
  'app',
];

/// Standard log levels for filter options.
const List<Level> knownLevels = [
  Level.debug,
  Level.info,
  Level.warning,
  Level.error,
];

/// A single log entry stored in the session buffer.
class SessionLogEntry {
  const SessionLogEntry({
    required this.time,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  final DateTime time;
  final Level level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  /// Filter bucket for [getFiltered] and viewer presets ([knownPrefixes]).
  ///
  /// Plain tags: `"logic: foo"` → `logic`. Dotted factory tags such as
  /// `"ctdev.running_game: foo"` map to the first segment when it is listed in
  /// [knownPrefixes] (here `ctdev`); otherwise the full tag before `:` is used.
  String get prefix {
    final msg = message;
    final colon = msg.indexOf(':');
    if (colon <= 0) return '';
    final full = msg.substring(0, colon).trim().toLowerCase();
    final dot = full.indexOf('.');
    if (dot > 0) {
      final head = full.substring(0, dot);
      if (knownPrefixes.contains(head)) {
        return head;
      }
    }
    return full;
  }

  /// Formatted main line: timestamp level message.
  String get formattedLine {
    final timeStr = formatOperatorLogTimestamp(time);
    final levelName = level.name.toUpperCase();
    return '$timeStr $levelName $message';
  }

  /// All lines for display (main line + optional error and stackTrace).
  List<String> get displayLines {
    final lines = <String>[formattedLine];
    if (error != null) {
      lines.add('  error: $error');
    }
    if (stackTrace != null) {
      lines.add('  stackTrace: $stackTrace');
    }
    return lines;
  }
}

class _DebugLevelFilter implements LogFilter {
  @override
  Level? level;

  @override
  Future<void> init() async {}

  @override
  Future<void> destroy() async {}

  @override
  bool shouldLog(LogEvent event) {
    return event.level >= Logger.level;
  }
}

/// In-memory session log buffer. Thread-safe for single-threaded Dart; call [init] once at startup.
class SessionLogBuffer {
  SessionLogBuffer({int maxEntries = defaultMaxEntries})
    : _maxEntries = maxEntries;

  final int _maxEntries;
  final List<SessionLogEntry> _entries = [];
  bool _initialized = false;

  /// Adds a log event to the buffer. Drops oldest entries when over [maxEntries].
  void add(LogEvent e) {
    final msg = e.message is String
        ? e.message as String
        : e.message.toString();
    final entry = SessionLogEntry(
      time: e.time,
      level: e.level,
      message: msg,
      error: e.error,
      stackTrace: e.stackTrace,
    );
    _entries.add(entry);
    while (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }
  }

  /// Returns a copy of entries that match the given filters.
  /// [selectedPrefixes]: empty means all; otherwise entry prefix must be in this set.
  /// [selectedLevels]: empty means all; otherwise entry level must be in this set.
  List<SessionLogEntry> getFiltered({
    Set<String> selectedPrefixes = const {},
    Set<Level> selectedLevels = const {},
  }) {
    final useAllPrefixes = selectedPrefixes.isEmpty;
    final useAllLevels = selectedLevels.isEmpty;
    return _entries.where((e) {
      if (!useAllLevels && !selectedLevels.contains(e.level)) return false;
      if (!useAllPrefixes) {
        final p = e.prefix;
        if (p.isEmpty || !selectedPrefixes.contains(p)) return false;
      }
      return true;
    }).toList();
  }

  /// Returns all entries (unfiltered). Copy of the list.
  List<SessionLogEntry> get entries => List<SessionLogEntry>.from(_entries);

  /// Whether [init] has been called.
  bool get isInitialized => _initialized;

  static final SessionLogBuffer _instance = SessionLogBuffer();

  static SessionLogBuffer get instance => _instance;

  /// Initializes the global session log buffer and registers a [Logger.addLogListener].
  /// Call once from app or ctdev main(). Logs at [Level.debug] and above are captured.
  static void init() {
    if (_instance._initialized) return;
    _instance._initialized = true;
    Logger.level = Level.debug;
    Logger.defaultFilter = () => _DebugLevelFilter();
    Logger.addLogListener((LogEvent e) {
      _instance.add(e);
    });
  }

  /// Test-only: resets the buffer and initialized state. Not for production.
  static void resetForTest() {
    _instance._entries.clear();
    _instance._initialized = false;
  }
}
