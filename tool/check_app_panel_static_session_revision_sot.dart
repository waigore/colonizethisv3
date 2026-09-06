import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/app-panel-static-session-revision.md (Refs #4734).
///
/// Under `app/lib/**`, only `panel_session_revision.dart` may construct the
/// combined `{gameId, turnNumber, worldRevision}` idiom from `Game`, declare a
/// local `provinceOverlayWorldRevision`, or re-inline the four-operand world hash.
const _canonicalHelper = 'app/lib/providers/panel_session_revision.dart';

const _gameIdToken = 'gameId: game.id';
const _turnNumberToken = 'turnNumber: game.worldState.turnState.turnNumber';
const _worldRevisionToken = 'worldRevision: panelWorldRevision';

bool appPanelStaticSessionRevisionSotPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith('app/lib/') &&
      normalized.endsWith('.dart') &&
      !normalized.endsWith('.g.dart') &&
      !normalized.endsWith('.gen.dart') &&
      !normalized.endsWith('.freezed.dart') &&
      !normalized.endsWith('.mocks.dart');
}

bool appPanelStaticSessionRevisionSotIsCanonical(String slashPath) {
  return slashPath.replaceAll('\\', '/') == _canonicalHelper;
}

bool _hasCombinedTripleIdiom(String source) {
  return source.contains(_gameIdToken) &&
      source.contains(_turnNumberToken) &&
      source.contains(_worldRevisionToken);
}

bool _hasProvinceOverlayWorldRevisionDecl(String source) {
  return RegExp(
    r'\b(?:int\s+)?provinceOverlayWorldRevision\s*\(',
  ).hasMatch(source);
}

bool _hasDuplicateFourOperandWorldHash(String source) {
  if (!source.contains('Object.hash(')) {
    return false;
  }
  return source.contains('purchasedTilesByTileKey.length') &&
      source.contains('tileKeysByRegionAndProvince.length') &&
      source.contains('players.length') &&
      source.contains('turnState.turnNumber');
}

bool appPanelStaticSessionRevisionSotIsViolation({
  required String relativePath,
  required String source,
}) {
  if (!appPanelStaticSessionRevisionSotPathInScope(relativePath)) {
    return false;
  }
  if (appPanelStaticSessionRevisionSotIsCanonical(relativePath)) {
    return false;
  }
  return _hasCombinedTripleIdiom(source) ||
      _hasProvinceOverlayWorldRevisionDecl(source) ||
      _hasDuplicateFourOperandWorldHash(source);
}

int runCheckAppPanelStaticSessionRevisionSot(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final appLibDir = Directory(p.join(repoRoot, 'app', 'lib'));
  if (!appLibDir.existsSync()) {
    logE('check_app_panel_static_session_revision_sot: app/lib not found');
    return 1;
  }

  final violations = <String>[];
  for (final entity in appLibDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final rel = p.relative(entity.path, from: repoRoot).replaceAll('\\', '/');
    if (appPanelStaticSessionRevisionSotIsViolation(
      relativePath: rel,
      source: entity.readAsStringSync(),
    )) {
      violations.add(rel);
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_app_panel_static_session_revision_sot: static revision triple '
      'and world-hash owned only by $_canonicalHelper.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_app_panel_static_session_revision_sot: ${violations.length} '
    'file(s) rebuild panel static session revision outside SoT:',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE(
    'Use panelStaticSessionRevision / panelWorldRevision in '
    '$_canonicalHelper (Refs #4734).',
  );
  return 1;
}

void main() {
  exit(runCheckAppPanelStaticSessionRevisionSot(Directory.current.path));
}
