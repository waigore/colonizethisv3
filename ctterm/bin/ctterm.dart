// ctterm entrypoint. SPEC/tui/ctterm.md. Run with: dart run ctterm [--data-dir <path>]

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_app.dart';
import 'package:ctterm/ctterm_log.dart';

final log_pkg.Logger _log = log_pkg.Logger();

void main(List<String> args) async {
  initCttermLogging();
  _log.i('tui: ctterm starting');

  String? dataDirOverride;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--data-dir' && i + 1 < args.length) {
      dataDirOverride = args[i + 1];
      i++;
      break;
    }
  }

  runApp(CttermApp(dataDirOverride: dataDirOverride));
}
