/// Setup-domain logging entrypoint (Refs #3290 C2 prerequisite).
///
/// Decoupled from the `colonizethis_logic` `logicLog` so the `setup/` source
/// tree moves cleanly into a future `colonizethis_setup` package without a
/// dependency on the thin logic core. One logger instance with the distinct
/// `setup` prefix, mirroring `diploLog`/`combatLog`/`economyLog` in the
/// already-split packages (per `colonizethis-core-principles`
/// one-logger-per-package convention).
library;

import 'package:colonizethis_logger/colonizethis_logger.dart';

export 'package:colonizethis_logger/colonizethis_logger.dart' show CtLogger;

/// Shared package-level [CtLogger] for `setup/` source files.
final setupLog = CtLogger('setup');
