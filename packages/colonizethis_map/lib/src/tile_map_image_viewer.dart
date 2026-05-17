import 'dart:io';

/// Tries to open [path] in the system default image viewer.
/// Respects SUPPRESS_IMAGE_VIEWER=1 env var to skip opening in non-interactive contexts.
bool openInDefaultViewer(String path) {
  if (Platform.environment['SUPPRESS_IMAGE_VIEWER'] == '1') {
    return false;
  }
  try {
    if (Platform.isMacOS) {
      Process.runSync('open', [path]);
      return true;
    }
    if (Platform.isLinux) {
      Process.runSync('xdg-open', [path]);
      return true;
    }
    if (Platform.isWindows) {
      Process.runSync('explorer', [path]);
      return true;
    }
  } on ProcessException {
    return false;
  } on ArgumentError {
    return false;
  }
  return false;
}
