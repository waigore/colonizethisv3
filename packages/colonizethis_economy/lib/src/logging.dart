/// Shared logging entrypoints for `lib/src/**`.
library;

import 'package:logger/logger.dart';

export 'package:colonizethis_economy/package_logger.dart'
    show CtLogger, packageLogger, economyLog;

/// Single debug-log gate shared by the economy auto-transport log helpers.
///
/// Returns `true` when the active logger level suppresses `debug` output, so
/// callers can early-return before building expensive log-detail strings.
/// Centralizes the `Level.debug.value < Logger.level.value` guard that would
/// otherwise be duplicated across the sea-transport and trade-interception
/// log helpers.
bool get economyDebugLogSuppressed => Level.debug.value < Logger.level.value;
