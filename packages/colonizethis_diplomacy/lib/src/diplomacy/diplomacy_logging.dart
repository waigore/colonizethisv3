/// Diplomacy-domain logging entrypoint (Refs #3290 C2 prerequisite).
///
/// Decoupled from the `colonizethis_logic` `logicLog` so the `diplomacy/` and
/// `dossier/` source trees move cleanly into `colonizethis_diplomacy` without a
/// dependency on the thin logic core. One logger instance with the distinct
/// `diplomacy` prefix, mirroring `combatLog`/`economyLog` in the already-split
/// leaf packages (per `colonizethis-core-principles` one-logger-per-package
/// convention).
library;

import 'package:colonizethis_logger/colonizethis_logger.dart';

export 'package:colonizethis_logger/colonizethis_logger.dart' show CtLogger;

/// Shared package-level [CtLogger] for `diplomacy/` and `dossier/` source files.
final diploLog = CtLogger('diplomacy');
