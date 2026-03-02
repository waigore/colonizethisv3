// ctterm entrypoint. SPEC/tui/ctterm.md. Run with: dart run ctterm [--data-dir <path>]

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_app.dart';
import 'package:ctterm/ctterm_log.dart';

final log_pkg.Logger _log = log_pkg.Logger();

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
  _log.i('tui: ctterm starting');

  runApp(CttermApp(dataDirOverride: dataDirOverride));
}
