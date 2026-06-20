import 'package:logger/logger.dart';

import 'operator_log_timestamp.dart';

/// [LogPrinter] that delegates to [PrettyPrinter] (same defaults as the
/// logger package's typical console configuration), then injects exactly one
/// [formatOperatorLogTimestamp]
/// segment on the first message row of each boxed event.
final class CtLoggerConsolePrinter extends LogPrinter {
  CtLoggerConsolePrinter({
    int stackTraceBeginIndex = 0,
    int? methodCount = 2,
    int? errorMethodCount = 8,
    int lineLength = 120,
    bool colors = true,
    bool printEmojis = true,
    Map<Level, bool> excludeBox = const {},
    bool noBoxingByDefault = false,
    List<String> excludePaths = const [],
    Map<Level, AnsiColor>? levelColors,
    Map<Level, String>? levelEmojis,
  }) : _inner = PrettyPrinter(
          stackTraceBeginIndex: stackTraceBeginIndex,
          methodCount: methodCount,
          errorMethodCount: errorMethodCount,
          lineLength: lineLength,
          colors: colors,
          printEmojis: printEmojis,
          excludeBox: excludeBox,
          noBoxingByDefault: noBoxingByDefault,
          excludePaths: excludePaths,
          levelColors: levelColors,
          levelEmojis: levelEmojis,
        );

  final PrettyPrinter _inner;

  @override
  List<String> log(LogEvent event) {
    final lines = List<String>.from(_inner.log(event));
    final msgFirstLine = _inner.stringifyMessage(event.message).split('\n').first;
    final ts = formatOperatorLogTimestamp(event.time);
    return _injectCanonicalTimestamp(lines, msgFirstLine, ts);
  }

  List<String> _injectCanonicalTimestamp(
    List<String> lines,
    String msgFirstLine,
    String ts,
  ) {
    final needle = '${PrettyPrinter.verticalLine} ';
    final bottomIdx = lines.indexWhere(
      (l) => l.contains(PrettyPrinter.bottomLeftCorner),
    );
    if (bottomIdx > 0) {
      for (var i = bottomIdx - 1; i >= 0; i--) {
        final line = lines[i];
        if (!line.contains(msgFirstLine)) {
          continue;
        }
        final injected = _insertTimestampAfterLeadingPipe(line, needle, ts);
        if (injected != line) {
          lines[i] = injected;
          return lines;
        }
      }
    }
    if (lines.isEmpty) {
      return lines;
    }
    final first = lines.first;
    if (first.contains(ts)) {
      return lines;
    }
    return ['$ts $first', ...lines.skip(1)];
  }

  /// Inserts [ts] immediately after the first `│ ` segment (PrettyPrinter's
  /// vertical rule + space), avoiding double injection.
  String _insertTimestampAfterLeadingPipe(String line, String needle, String ts) {
    if (line.contains(ts)) {
      return line;
    }
    final idx = line.indexOf(needle);
    if (idx < 0) {
      return line;
    }
    final insertAt = idx + needle.length;
    return '${line.substring(0, insertAt)}$ts ${line.substring(insertAt)}';
  }
}
