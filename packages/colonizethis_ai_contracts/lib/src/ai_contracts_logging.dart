/// AI-contracts logging entrypoint (Refs #3290 C4).
///
/// Decoupled from the `colonizethis_logic` `logicLog` so the AI planning source
/// tree moves cleanly into `colonizethis_ai_contracts` without a dependency on
/// the thin logic core. One logger instance with the distinct `ai_contracts`
/// prefix, mirroring `ordersLog`/`turnLog`/`combatLog`/`economyLog`/`diploLog`
/// in the other split packages (per `colonizethis-core-principles`
/// one-logger-per-package convention).
library;

import 'package:colonizethis_logger/colonizethis_logger.dart';

export 'package:colonizethis_logger/colonizethis_logger.dart' show CtLogger;

/// Shared package-level [CtLogger] for `src/ai/` source files.
final aiContractsLog = CtLogger('ai_contracts');
