import 'package:colonizethis_app/config/ct_debug_console.dart';

/// Canonical application version label used in shell surfaces.
const String kAppVersion = 'v0.0.1';

/// Compile-time debug indicator suffix for user-visible title/version strings.
const String kDebugDisplaySuffix = ' (debug)';

String formatDebugAwareTitle(String baseTitle, {bool? debugConsoleEnabled}) {
  return _formatDebugAware(baseTitle, debugConsoleEnabled: debugConsoleEnabled);
}

String formatDebugAwareVersion(
  String baseVersion, {
  bool? debugConsoleEnabled,
}) {
  return _formatDebugAware(
    baseVersion,
    debugConsoleEnabled: debugConsoleEnabled,
  );
}

String appDisplayVersion({bool? debugConsoleEnabled}) {
  return formatDebugAwareVersion(
    kAppVersion,
    debugConsoleEnabled: debugConsoleEnabled,
  );
}

String _formatDebugAware(String baseValue, {bool? debugConsoleEnabled}) {
  final enabled = debugConsoleEnabled ?? kCtDebugConsoleEnabled;
  if (!enabled || baseValue.endsWith(kDebugDisplaySuffix)) {
    return baseValue;
  }
  return '$baseValue$kDebugDisplaySuffix';
}
