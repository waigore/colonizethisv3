import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_per_pass_nw_owner_map.dart';

void main() {
  group('findSetupPerPassNwOwnerMapViolations', () {
    const canonicalPath =
        'packages/colonizethis_setup/lib/src/setup/advanced_start_nw_owner_lookup.dart';
    const worldPath =
        'packages/colonizethis_setup/lib/src/setup/advanced_start_bootstrap_world.dart';
    const colonizationPath =
        'packages/colonizethis_setup/lib/src/setup/advanced_start_bootstrap_colonization.dart';

    test('flags private linear owner lookup helpers', () {
      const src = '''
String? _ownerIdForLocalProvince(Game game, String localProvinceId) {
  return null;
}
final owners = nwOwnerByLocalProvinceId(game);
''';
      final violations = findSetupPerPassNwOwnerMapViolations(
        sourcesByPath: const {worldPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('nwOwnerByLocalProvinceId'));
    });

    test('flags linear scan that returns ownerId via prefixedFrom', () {
      const src = '''
for (final province in game.worldState.newWorld.provinces) {
  final id = ProvinceId.prefixedFrom(province.regionId, province.id);
  if (id == fullId) return province.ownerId;
}
final owners = nwTribeOwnerByLocalProvinceId(game);
''';
      final violations = findSetupPerPassNwOwnerMapViolations(
        sourcesByPath: const {colonizationPath: src},
      );
      expect(
        violations.any((v) => v.message.contains('per-pass owner map')),
        isTrue,
      );
    });

    test('flags missing shared helper call sites', () {
      const worldSrc = 'void apply() {}';
      const colonizationSrc = 'void apply() {}';
      final violations = findSetupPerPassNwOwnerMapViolations(
        sourcesByPath: const {
          worldPath: worldSrc,
          colonizationPath: colonizationSrc,
        },
      );
      expect(
        violations.any((v) => v.message.contains('nwOwnerByLocalProvinceId')),
        isTrue,
      );
      expect(
        violations.any(
          (v) => v.message.contains('nwTribeOwnerByLocalProvinceId'),
        ),
        isTrue,
      );
    });

    test('exempts the canonical owner-lookup module', () {
      const src = '''
for (final province in game.worldState.newWorld.provinces) {
  final id = ProvinceId.prefixedFrom(province.regionId, province.id);
  owners[localId] = province.ownerId;
}
String? _ownerIdForLocalProvince(Game game, String id) => null;
''';
      final violations = findSetupPerPassNwOwnerMapViolations(
        sourcesByPath: const {canonicalPath: src},
      );
      expect(violations, isEmpty);
    });

    test('ignores comment lines', () {
      const src = '''
// String? _ownerIdForLocalProvince(Game game, String localProvinceId) {
/// Prefer nwOwnerByLocalProvinceId over _tribeOwnerForLocalProvince.
final owners = nwOwnerByLocalProvinceId(game);
''';
      final violations = findSetupPerPassNwOwnerMapViolations(
        sourcesByPath: const {worldPath: src},
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup source tree', () {
      final repoRoot = _repoRoot();
      final code = runCheckSetupPerPassNwOwnerMap(
        repoRoot,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });
}

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    final manifest = File(
      p.join(dir.path, 'tool', 'ct_repo_lint_manifest.yaml'),
    );
    if (manifest.existsSync()) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current.path;
    }
    dir = parent;
  }
}
