import 'package:logger/logger.dart';

import 'ct_logger_console_printer.dart';

class CtLogger {
  final Logger _log;
  final String prefix;

  CtLogger(this.prefix) : _log = Logger(printer: CtLoggerConsolePrinter());

  void d(String msg, {Object? error, StackTrace? stackTrace}) =>
      _log.d('$prefix: $msg', error: error, stackTrace: stackTrace);
  void i(String msg, {Object? error, StackTrace? stackTrace}) =>
      _log.i('$prefix: $msg', error: error, stackTrace: stackTrace);
  void w(String msg, {Object? error, StackTrace? stackTrace}) =>
      _log.w('$prefix: $msg', error: error, stackTrace: stackTrace);
  void e(String msg, {Object? error, StackTrace? stackTrace}) =>
      _log.e('$prefix: $msg', error: error, stackTrace: stackTrace);
  void t(String msg, {Object? error, StackTrace? stackTrace}) =>
      _log.t('$prefix: $msg', error: error, stackTrace: stackTrace);
  void f(String msg, {Object? error, StackTrace? stackTrace}) =>
      _log.f('$prefix: $msg', error: error, stackTrace: stackTrace);
  void log(Level level, String msg, {Object? error, StackTrace? stackTrace}) =>
      _log.log(level, '$prefix: $msg', error: error, stackTrace: stackTrace);
  void trace(String msg, {Object? error, StackTrace? stackTrace}) =>
      _log.t('$prefix: $msg', error: error, stackTrace: stackTrace);
  void debug(String msg, {Object? error, StackTrace? stackTrace}) =>
      _log.d('$prefix: $msg', error: error, stackTrace: stackTrace);
  void info(String msg, {Object? error, StackTrace? stackTrace}) =>
      _log.i('$prefix: $msg', error: error, stackTrace: stackTrace);
  void warning(String msg, {Object? error, StackTrace? stackTrace}) =>
      _log.w('$prefix: $msg', error: error, stackTrace: stackTrace);
  void error(String msg, {Object? error, StackTrace? stackTrace}) =>
      _log.e('$prefix: $msg', error: error, stackTrace: stackTrace);
  void fatal(String msg, {Object? error, StackTrace? stackTrace}) =>
      _log.f('$prefix: $msg', error: error, stackTrace: stackTrace);

  static Level get level => Logger.level;
  static set level(Level value) => Logger.level = value;

  /// Whether a [Level.debug] event would currently pass the active
  /// [Logger.level] threshold. Guard hot-path [d] calls whose message argument
  /// eagerly builds collections/strings so the work is skipped when debug
  /// output is filtered (Refs #3288; see SPEC/program/colonizethis-logger.md
  /// §2.6 and the turn-resolution budget § Control logging overhead).
  bool get debugEnabled => Logger.level.value <= Level.debug.value;

  /// Whether a [Level.info] event would currently pass the active
  /// [Logger.level] threshold. See [debugEnabled].
  bool get infoEnabled => Logger.level.value <= Level.info.value;
}

CtLogger logicLogger([String? subPrefix]) =>
    subPrefix != null ? CtLogger('logic.$subPrefix') : CtLogger('logic');

CtLogger aiLogger([String? subPrefix]) =>
    subPrefix != null ? CtLogger('ai.$subPrefix') : CtLogger('ai');

CtLogger dataLogger([String? subPrefix]) =>
    subPrefix != null ? CtLogger('data.$subPrefix') : CtLogger('data');

CtLogger mapLogger([String? subPrefix]) =>
    subPrefix != null ? CtLogger('map.$subPrefix') : CtLogger('map');

CtLogger saveLogger([String? subPrefix]) =>
    subPrefix != null ? CtLogger('save.$subPrefix') : CtLogger('save');

CtLogger gameLogger([String? subPrefix]) =>
    subPrefix != null ? CtLogger('game.$subPrefix') : CtLogger('game');

CtLogger appLogger([String? subPrefix]) =>
    subPrefix != null ? CtLogger('app.$subPrefix') : CtLogger('app');

CtLogger ctdevLogger([String? subPrefix]) =>
    subPrefix != null ? CtLogger('ctdev.$subPrefix') : CtLogger('ctdev');
