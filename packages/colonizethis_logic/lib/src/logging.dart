/// Shared logging entrypoints for `lib/src/**` (Refs #2391 AC5).
///
/// Import this library instead of reaching for [package_logger] directly so
/// package-level logging stays on one canonical path.
library;

export 'package:colonizethis_logic/package_logger.dart'
    show CtLogger, logicLog, packageLogger;
