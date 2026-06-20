import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3574).
///
/// Enforces the `colonizethis_map` generation→render layer boundary: only the
/// PNG **render layer** may depend on `package:image`. Generation passes and
/// view-model building must stay image-free so the package's internal layering
/// (gen → view inputs → render) is one-directional and a future `lib/src/gen/`
/// /`view/`/`render/` reorganization (issue #3574 slice 5) is a pure relocation.
///
/// A violation is any `import` / `export` of `package:image` in a
/// `packages/colonizethis_map/lib/**` Dart file that is **not** in the
/// documented render-layer allowlist ([_renderLayerAllowlist]). Comment lines
/// are ignored. The allowlist is the pre-reorg definition of the render layer;
/// after slice 5 it can be replaced by a `lib/src/render/**` path scope.
const _mapLibRoot = 'packages/colonizethis_map/lib';

/// Render-layer files permitted to depend on `package:image` (paths relative to
/// the repo root). These are the only `colonizethis_map` libraries that encode
/// PNGs; everything else (generation passes, view-model builders, grid/topology
/// helpers) must remain image-free.
const _renderLayerAllowlist = <String>{
  'packages/colonizethis_map/lib/src/tile_map_visualization.dart',
  'packages/colonizethis_map/lib/src/tile_map_visualization_shared.dart',
  'packages/colonizethis_map/lib/src/game_world_state_map_visualizer.dart',
  'packages/colonizethis_map/lib/src/multi_region_map_rendering.dart',
  'packages/colonizethis_map/lib/src/tile_map_resource_legend.dart',
};

/// Matches an `import`/`export` directive that references `package:image`.
/// The trailing `[/'"]` ensures a same-prefix package such as
/// `package:image_picker/...` is not matched.
final RegExp _imageImportPattern = RegExp(
  '''(?:import|export)\\s+['"]package:image[/'"]''',
);

/// True when [line] is a pure comment line so prose is not treated as code.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

void main() {
  exit(runCheckMapGenNoImageImport(Directory.current.path));
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckMapGenNoImageImport(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _mapLibRoot));
  if (!libDir.existsSync()) {
    logE('check_map_gen_no_image_import: missing $libDir');
    return 1;
  }

  final violations = <MapGenImageImportViolation>[];
  for (final file in libDir.listSync(recursive: true, followLinks: false)) {
    if (file is! File || !file.path.endsWith('.dart')) {
      continue;
    }
    final relPath = p.normalize(p.relative(file.path, from: root));
    violations.addAll(
      findMapGenImageImportViolations(
        relativePath: relPath,
        source: file.readAsStringSync(),
        renderLayerAllowlist: _renderLayerAllowlist,
      ),
    );
  }

  if (violations.isEmpty) {
    logI('colonizethis_map generation→image boundary check passed.');
    return 0;
  }

  logE(
    'ERROR: Only the colonizethis_map render layer may import package:image '
    '(${_renderLayerAllowlist.length} allowlisted PNG-encoding files). '
    'Generation passes and view-model builders must stay image-free; move '
    'rendering work into the render layer or extend the documented allowlist '
    'in tool/check_map_gen_no_image_import.dart with rationale:',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

List<MapGenImageImportViolation> findMapGenImageImportViolations({
  required String relativePath,
  required String source,
  required Set<String> renderLayerAllowlist,
}) {
  if (renderLayerAllowlist.contains(relativePath)) {
    return const [];
  }
  final lines = source.split('\n');
  final violations = <MapGenImageImportViolation>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) {
      continue;
    }
    if (!_imageImportPattern.hasMatch(line)) {
      continue;
    }
    violations.add(
      MapGenImageImportViolation(
        path: relativePath,
        line: i + 1,
        message:
            'package:image import outside the render layer; keep generation / '
            'view-model code image-free (render layer only).',
      ),
    );
  }
  return violations;
}

class MapGenImageImportViolation {
  const MapGenImageImportViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
