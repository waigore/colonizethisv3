/// Orders-domain logging entrypoint (Refs #3290 C2 prerequisite).
///
/// Decoupled from the `colonizethis_logic` `logicLog` so the `orders/` source
/// tree moves cleanly into a future `colonizethis_orders` package without a
/// dependency on the thin logic core. One logger instance with the distinct
/// `orders` prefix, mirroring `setupLog`/`diploLog`/`combatLog`/`economyLog`
/// in the already-split packages (per `colonizethis-core-principles`
/// one-logger-per-package convention).
library;

import 'package:colonizethis_logger/colonizethis_logger.dart';

export 'package:colonizethis_logger/colonizethis_logger.dart' show CtLogger;

/// Shared package-level [CtLogger] for `orders/` source files.
final ordersLog = CtLogger('orders');
