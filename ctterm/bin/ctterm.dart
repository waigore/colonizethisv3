// ctterm entrypoint. SPEC/tui/ctterm.md. Run with: dart run ctterm [--data-dir <path>]

import 'dart:async';

import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_app.dart';
import 'package:ctterm/ctterm_log.dart';
import 'package:ctterm/save_service.dart';
import 'package:session_log_buffer/session_log_buffer.dart';

final _log = tuiLogger();

void main(List<String> args) async {
  String? dataDirOverride;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--data-dir' && i + 1 < args.length) {
      dataDirOverride = args[i + 1];
      i++;
      break;
    }
  }

  initCttermLogging(dataDirOverride);
  SessionLogBuffer.init();
  _log.i('ctterm starting');

  var initialLockDetected = false;
  try {
    await ensureSaveServiceReady(dataDirOverride);
  } on StaleLockException catch (e) {
    _log.d('lock detected at ${e.dataDir}, showing prompt');
    initialLockDetected = true;
  } catch (e, st) {
    _log.w(
      'save service pre-init failed (menu may show Loading then recover)',
      error: e,
      stackTrace: st,
    );
  }

  runZonedGuarded(
    () {
      runApp(CttermApp(
        dataDirOverride: dataDirOverride,
        initialLockDetected: initialLockDetected,
      ));
    },
    (Object error, StackTrace stackTrace) {
      tuiLogger().e(
        'uncaught async error',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
