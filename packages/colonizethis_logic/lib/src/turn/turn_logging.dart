/// Turn-domain logging entrypoint (Refs #3290 C3 prerequisite).
///
/// Decoupled from the `colonizethis_logic` `logicLog` so the `turn/` source
/// tree moves cleanly into a future `colonizethis_turn` package without a
/// dependency on the thin logic core. One logger instance with the distinct
/// `turn` prefix, mirroring `ordersLog`/`setupLog`/`diploLog`/`combatLog`/
/// `economyLog` in the already-split packages (per `colonizethis-core-principles`
/// one-logger-per-package convention).
library;

import 'package:colonizethis_logger/colonizethis_logger.dart';

export 'package:colonizethis_logger/colonizethis_logger.dart' show CtLogger;

/// Shared package-level [CtLogger] for `turn/` source files.
final turnLog = CtLogger('turn');
