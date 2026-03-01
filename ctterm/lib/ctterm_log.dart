// ctterm logging. SPEC/tui/ctterm.md §5. Use prefixes tui:, tui:menu:, tui:save:, tui:nav:, etc.

import 'package:logger/logger.dart';

/// Initializes ctterm logging. Call from main() before runApp.
/// Use loggers with prefix names in code, e.g. Logger('tui:save:').
void initCttermLogging() {
  Logger.level = Level.debug;
}
