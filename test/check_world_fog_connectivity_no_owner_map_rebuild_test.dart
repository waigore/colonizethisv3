import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_world_fog_connectivity_no_owner_map_rebuild.dart';

void main() {
  group('runCheckWorldFogConnectivityNoOwnerMapRebuild', () {
    test('fails when an in-scope fog file calls ownerByProvinceIdMap', () {
      final temp = Directory.systemTemp.createTempSync('world-owner-map-');
      try {
        final fogDir = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_world',
            'lib',
            'src',
            'world',
          ),
        )..createSync(recursive: true);
        File(
          p.join(fogDir.path, 'fog_resolution_explorer_spy_decay.dart'),
        ).writeAsStringSync(
          'void apply() {\n'
          '  final m = ownerByProvinceIdMap(world);\n'
          '}\n',
        );

        final errors = <String>[];
        final exitCode = runCheckWorldFogConnectivityNoOwnerMapRebuild(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(
          errors.join('\n'),
          contains('fog_resolution_explorer_spy_decay.dart'),
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when fog uses ProvinceOwnerCache only', () {
      final temp = Directory.systemTemp.createTempSync('world-owner-ok-');
      try {
        final fogDir = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_world',
            'lib',
            'src',
            'world',
          ),
        )..createSync(recursive: true);
        File(
          p.join(fogDir.path, 'fog_resolution_explorer_spy_decay.dart'),
        ).writeAsStringSync(
          'void apply() {\n'
          '  final m = ProvinceOwnerCache.of(world).ownerByProvinceId;\n'
          '}\n',
        );
        File(p.join(fogDir.path, 'province_traversal.dart')).writeAsStringSync(
          'Map<String, String?> ownerByProvinceIdMap(WorldState world) =>\n'
          '    ProvinceOwnerCache.of(world).ownerByProvinceId;\n',
        );

        final exitCode = runCheckWorldFogConnectivityNoOwnerMapRebuild(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('worldFogConnectivityOwnershipScanPathInScope', () {
    test('includes fog/connectivity basenames only', () {
      expect(
        worldFogConnectivityOwnershipScanPathInScope(
          'packages/colonizethis_world/lib/src/world/'
          'connectivity_faction_input.dart',
        ),
        isTrue,
      );
      expect(
        worldFogConnectivityOwnershipScanPathInScope(
          'packages/colonizethis_world/lib/src/world/province_traversal.dart',
        ),
        isFalse,
      );
    });
  });
}
