import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #4582).
///
/// OverlayEntry + DismissIntent + dialogScrim together may appear only in
/// `app/lib/features/game/widgets/shell/chrome_anchored_popover.dart`.
const _canonicalHelper =
    'app/lib/features/game/widgets/shell/chrome_anchored_popover.dart';

bool appChromePopoverSotPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith('app/lib/') &&
      normalized.endsWith('.dart') &&
      !normalized.endsWith('.g.dart') &&
      !normalized.endsWith('.gen.dart') &&
      !normalized.endsWith('.freezed.dart') &&
      !normalized.endsWith('.mocks.dart');
}

bool appChromePopoverSotIsCanonical(String slashPath) {
  return slashPath.replaceAll('\\', '/') == _canonicalHelper;
}

bool appChromePopoverSotIsViolation({
  required String relativePath,
  required String source,
}) {
  if (!appChromePopoverSotPathInScope(relativePath)) {
    return false;
  }
  if (appChromePopoverSotIsCanonical(relativePath)) {
    return false;
  }
  return source.contains('OverlayEntry') &&
      source.contains('DismissIntent') &&
      source.contains('dialogScrim');
}

int runCheckAppChromePopoverSot(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final appLibDir = Directory(p.join(repoRoot, 'app', 'lib'));
  if (!appLibDir.existsSync()) {
    logE('check_app_chrome_popover_sot: app/lib not found');
    return 1;
  }

  final violations = <String>[];
  for (final entity in appLibDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final rel = p.relative(entity.path, from: repoRoot).replaceAll('\\', '/');
    if (appChromePopoverSotIsViolation(
      relativePath: rel,
      source: entity.readAsStringSync(),
    )) {
      violations.add(rel);
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_app_chrome_popover_sot: OverlayEntry+DismissIntent+dialogScrim '
      'only in $_canonicalHelper.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_app_chrome_popover_sot: ${violations.length} file(s) reimplement '
    'the chrome popover overlay stack:',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE('Use showChromeAnchoredPopover in $_canonicalHelper (Refs #4582).');
  return 1;
}

void main() {
  exit(runCheckAppChromePopoverSot(Directory.current.path));
}
